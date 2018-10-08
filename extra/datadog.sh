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
DD_APM_LOG="$DD_LOG_DIR/datadog-apm.log"

# Move Datadog config files into place
cp $DATADOG_CONF.example $DATADOG_CONF

# Update the Datadog conf yaml with the correct conf.d and checks.d
sed -i -e"s|^.*confd_path:.*$|confd_path: $DD_CONF_DIR/conf.d|" $DATADOG_CONF
sed -i -e"s|^.*additional_checksd:.*$|additional_checksd: $DD_DIR/checks.d|" $DATADOG_CONF

# Include application's datadog configs
APP_DATADOG_CONF_DIR="/app/datadog/conf.d"

for file in "$APP_DATADOG_CONF_DIR"/*.yaml; do
  test -e "$file" || continue # avoid errors when glob doesn't match anything
  filename=$(basename -- "$file")
  filename="${filename%.*}"
  mkdir -p "$DD_CONF_DIR/conf.d/${filename}.d"
  cp $file "$DD_CONF_DIR/conf.d/${filename}.d/conf.yaml"
done

# Add tags to the config file
DYNOHOST="$( hostname )"
DYNOTYPE=${DYNO%%.*}
TAGS="tags:\n  - dyno:$DYNO\n  - dynotype:$DYNOTYPE"

if [ -n "$HEROKU_APP_NAME" ]; then
  TAGS="$TAGS\n  - appname:$HEROKU_APP_NAME"
fi

# Convert comma delimited tags from env vars to yaml
if [ -n "$DD_TAGS" ]; then
  DD_TAGS=$(sed "s/,[ ]\?/\\\n  - /g" <<< $DD_TAGS)
  TAGS="$TAGS\n  - $DD_TAGS"
  # User set tags are now in YAML, clear the env var.
  export DD_TAGS=""
fi

# Inject tags after example tags.
sed -i "s/^#   - role:database$/#   - role:database\n$TAGS/" $DATADOG_CONF

# Uncomment APM configs and add the log file location.
sed -i -e"s|^# apm_config:$|apm_config:\n    log_file: $DD_APM_LOG|" $DATADOG_CONF

# Uncomment the Process Agent configs and enable.
if [ "$DD_PROCESS_AGENT" == "true" ]; then
  sed -i -e"s|^# process_config:$|process_config:\n    enabled: $DD_PROCESS_AGENT|" $DATADOG_CONF
fi

# For a list of env vars to override datadog.yaml, see:
# https://github.com/DataDog/datadog-agent/blob/master/pkg/config/config.go#L145

if [ -z "$DD_API_KEY" ]; then
  echo "DD_API_KEY environment variable not set. Run: heroku config:add DD_API_KEY=<your API key>"
  DISABLE_DATADOG_AGENT=1
fi

if [ -z "$DD_HOSTNAME" ]; then
  if [ "$DD_DYNO_HOST" == "true" ]; then
    # Set the hostname to dyno name and ensure rfc1123 compliance.
    HAN=$( echo $HEROKU_APP_NAME | sed -e 's/[^a-zA-Z0-9-]/-/g' -e 's/^-//g' )
    if [ "$HAN" != "$HEROKU_APP_NAME" ]; then
      echo "WARNING: The appname \"$HEROKU_APP_NAME\" contains invalid characters. Using \"$HAN\" instead."
    fi

    D=$( echo $DYNO | sed -e 's/[^a-zA-Z0-9.-]/-/g' -e 's/^-//g' )
    export DD_HOSTNAME="$HAN.$D"
  else
    # Set the hostname to the dyno host
    export DD_HOSTNAME=$( echo $DYNOHOST | sed -e 's/[^a-zA-Z0-9-]/-/g' -e 's/^-//g' )
  fi
else
  # Generate a warning about DD_HOSTNAME deprecation.
  echo "WARNING: DD_HOSTNAME is deprecated. Setting this environment variable may result in metrics errors. To remove it, run: heroku config:unset DD_HOSTNAME"
fi


if [ -n "$DISABLE_DATADOG_AGENT" ]; then
  echo "The Datadog Agent has been disabled. Unset the DISABLE_DATADOG_AGENT or set missing environment variables."
else
  # Setup Python Path
  DD_PYTHONPATH="$DD_DIR/embedded/lib/python2.7"
  for python_mod_dir in $(ls -d $DD_DIR/embedded/lib/python*/site-packages 2>/dev/null); do
    DD_PYTHONPATH="${python_mod_dir}:${DD_PYTHONPATH}"
  done
  DD_PYTHONPATH="$DD_DIR/embedded/lib/python2.7/plat-linux2:$DD_PYTHONPATH"
  DD_PYTHONPATH="$DD_DIR/embedded/lib/python2.7/lib-tk:$DD_PYTHONPATH"
  DD_PYTHONPATH="$DD_DIR/embedded/lib/python2.7/lib-dynload:$DD_PYTHONPATH"
  DD_PYTHONPATH="$DD_DIR/bin/agent/dist:$DD_PYTHONPATH"

  # Get the Agent version number
  DD_VERSION=`expr "$($DD_BIN_DIR/agent version)" : 'Agent \([0-9]\+\.[0-9]\+.[0-9]\+\)'`

  # Prior to Agent 2.4.1, the command is "start"
  RUN_VERSION="6.4.1"
  if [ "$DD_VERSION" == "`echo -e "$RUN_VERSION\n$DD_VERSION" | sort -V | head -n1`" ]; then
    RUN_COMMAND="start"
  else
    RUN_COMMAND="run"
  fi

  # Run the Datadog Agent
  echo "Starting Datadog Agent on $DD_HOSTNAME"
  bash -c "PYTHONPATH=\"$DD_PYTHONPATH\" $DD_BIN_DIR/agent $RUN_COMMAND -c $DATADOG_CONF 2>&1 &"

  # The Trace Agent will run by default.
  if [ "$DD_APM_ENABLED" == "false" ]; then
    echo "The Datadog Trace Agent has been disabled. Set DD_APM_ENABLED to true or unset it."
  else
    echo "Starting Datadog Trace Agent on $DD_HOSTNAME"
    bash -c "$DD_DIR/embedded/bin/trace-agent -config $DATADOG_CONF 2>&1 &"
  fi
fi
