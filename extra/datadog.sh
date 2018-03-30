#!/usr/bin/env bash

# Setup Locations
APT_DIR="$HOME/.apt"
DD_DIR="$APT_DIR/opt/datadog-agent"
DD_BIN_DIR="$DD_DIR/bin/agent"
DD_LOG_DIR="$APT_DIR/var/log/datadog"
DD_CONF_DIR="$APT_DIR/etc/datadog-agent"
DATADOG_CONF="$DD_CONF_DIR/datadog.yaml"

# Update Env Vars with new paths for apt packages
export PATH="$APT_DIR/usr/bin:$DD_BIN_DIR:$PATH"
export LD_LIBRARY_PATH="$APT_DIR/usr/lib/x86_64-linux-gnu:$APT_DIR/usr/lib:$LD_LIBRARY_PATH"
export LIBRARY_PATH="$APT_DIR/usr/lib/x86_64-linux-gnu:$APT_DIR/usr/lib:$LIBRARY_PATH"
export INCLUDE_PATH="$APT_DIR/usr/include:$APT_DIR/usr/include/x86_64-linux-gnu:$INCLUDE_PATH"
export PKG_CONFIG_PATH="$APT_DIR/usr/lib/x86_64-linux-gnu/pkgconfig:$APT_DIR/usr/lib/pkgconfig:$PKG_CONFIG_PATH"

# Set Datadog configs
export DD_LOG_FILE="$DD_LOG_DIR/datadog.log"
export DD_PROC_LOG="$DD_LOG_DIR/datadog-process.log"
export DD_CONF_PATH="$DD_CONF_DIR"

# Move Datadog config files into place
cp $DATADOG_CONF.example $DATADOG_CONF

# Update the Datadog conf yaml with the correct conf.d and checks.d
sed -i -e"s|^.*confd_path:.*$|confd_path: $DD_CONF_DIR/conf.d|" $DATADOG_CONF
sed -i -e"s|^.*additional_checksd:.*$|additional_checksd: $DD_DIR/checks.d|" $DATADOG_CONF

# Add tags to the config file
DYNOHOST="$( hostname )"
TAGS="tags:\n  - dyno:$DYNO\n  - dynohost:$DYNOHOST"
# Convert comma delimited tags from env vars to yaml
if [ -n "$DD_TAGS" ]; then
  DD_TAGS=$(sed "s/,[ ]\?/\\\n  - /g" <<< $DD_TAGS)
  TAGS="$TAGS\n  - $DD_TAGS"
fi
# Inject tags after example tags.
sed -i "s/^#   - role:database$/#   - role:database\n$TAGS/" $DATADOG_CONF

# Enable process monitoring
sed -i -e"s|^# process_config:|process_config:\n  enabled: \"true\"\n  log_file: \"$DD_PROC_LOG\"|" $DATADOG_CONF

# For a list of env vars to override datadog.yaml, see:
# https://github.com/DataDog/datadog-agent/blob/master/pkg/config/config.go#L145

if [ -z "$DD_API_KEY" ]; then
  echo "DD_API_KEY environment variable not set. Run: heroku config:add DD_API_KEY=<your API key>"
  DISABLE_DATADOG_AGENT=1
fi

if [ -z "$DD_HOSTNAME" ]; then
  echo 'DD_HOSTNAME environment variable not set. Run: heroku config:set DD_HOSTNAME=$(heroku apps:info|grep ===|cut -d' ' -f2)'
  DISABLE_DATADOG_AGENT=1
fi

if [ -n "$DISABLE_DATADOG_AGENT" ]; then
  echo "The Datadog Agent has been disabled. Unset the DISABLE_DATADOG_AGENT or set missing environment variables."
else
  # Run the Datadog Agent
  echo "Starting Datadog Agent on dyno $DYNO"
  bash -c "PYTHONPATH=$DD_DIR/embedded/lib/python2.7 $DD_BIN_DIR/agent start -c $DATADOG_CONF 2>&1 &"

  # The Trace Agent will run by default.
  if [ "$DD_APM_ENABLED" == "false" ]; then
    echo "The Datadog Trace Agent has been disabled. Set DD_APM_ENABLED to true or unset it."
  else
    echo "Starting Datadog Trace Agent on dyno $DYNO"
    bash -c "$DD_DIR/embedded/bin/trace-agent -config $DATADOG_CONF 2>&1 &"
  fi
fi
