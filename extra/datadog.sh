#!/usr/bin/env bash

# Setup Locations
APT_DIR="$HOME/.apt"
DD_DIR="$APT_DIR/opt/datadog-agent"
DD_RUN_DIR="$DD_DIR/run"
# Export DD_BIN_DIR to be used by the wrapper
export DD_BIN_DIR="$DD_DIR/bin/agent"
DD_LOG_DIR="$APT_DIR/var/log/datadog"
DD_CONF_DIR="$APT_DIR/etc/datadog-agent"
DD_INSTALL_INFO="$DD_CONF_DIR/install_info"
export DATADOG_CONF="$DD_CONF_DIR/datadog.yaml"

# Update Env Vars with new paths for apt packages
export PATH="$APT_DIR/usr/bin:$DD_BIN_DIR:$PATH"
# Export agent's LD_LIBRARY_PATH to be used by the agent-wrapper
export DD_LD_LIBRARY_PATH="$APT_DIR/opt/datadog-agent/embedded/lib:$APT_DIR/usr/lib/x86_64-linux-gnu:$APT_DIR/usr/lib"

# Get the lower case for the log level
DD_LOG_LEVEL_LOWER=$(echo "$DD_LOG_LEVEL" | tr '[:upper:]' '[:lower:]')

# Set Datadog configs
export DD_LOG_FILE="$DD_LOG_DIR/datadog.log"
DD_APM_LOG="$DD_LOG_DIR/datadog-apm.log"
DD_PROC_LOG="$DD_LOG_DIR/datadog-proc.log"

# Move Datadog config files into place
cp "$DATADOG_CONF.example" "$DATADOG_CONF"

# Update the Datadog conf yaml with the correct conf.d and checks.d and the correct run path
sed -i -e"s|^.*confd_path:.*$|confd_path: $DD_CONF_DIR/conf.d|" "$DATADOG_CONF"
sed -i -e"s|^.*additional_checksd:.*$|additional_checksd: $DD_CONF_DIR/checks.d\nrun_path: $DD_RUN_DIR|" "$DATADOG_CONF"

# Update the Datadog conf yaml to disable cloud provider metadata
sed -i -e"s|^.*cloud_provider_metadata:.*$|cloud_provider_metadata: []|" "$DATADOG_CONF"

# Include application's datadog configs
APP_DATADOG_DEFAULT="/app/datadog"
APP_DATADOG="${DD_HEROKU_CONF_FOLDER:=$APP_DATADOG_DEFAULT}"
APP_DATADOG_CONF_DIR="$APP_DATADOG/conf.d"
APP_DATADOG_CHECKS_DIR="$APP_DATADOG/checks.d"

# Agent integrations configuration
for file in "$APP_DATADOG_CONF_DIR"/*.yaml; do
  test -e "$file" || continue # avoid errors when glob doesn't match anything
  filename="$(basename -- "$file")"
  filename="${filename%.*}"
  mkdir -p "$DD_CONF_DIR/conf.d/${filename}.d"
  cp "$file" "$DD_CONF_DIR/conf.d/${filename}.d/conf.yaml"
done

# Custom checks configuration
for file in "$APP_DATADOG_CHECKS_DIR"/*.yaml; do
  test -e "$file" || continue # avoid errors when glob doesn't match anything
  cp "$file" "$DD_CONF_DIR/conf.d/"
done

# Custom checks code
for file in "$APP_DATADOG_CHECKS_DIR"/*.py; do
  test -e "$file" || continue # avoid errors when glob doesn't match anything
  cp "$file" "$DD_CONF_DIR/checks.d/"
done

# Add tags to the config file
DYNOHOST="$(hostname )"
DYNOTYPE=${DYNO%%.*}
BUILDPACKVERSION="dev"
DYNO_TAGS="dyno:$DYNO dynotype:$DYNOTYPE buildpackversion:$BUILDPACKVERSION"

# We want always to have the Dyno ID as a host alias to improve correlation
export DD_HOST_ALIASES="$DYNOHOST"

# Include install method
echo -e "install_method:\n  tool: heroku\n  tool_version: heroku\n  installer_version: heroku-$BUILDPACKVERSION" > "$DD_INSTALL_INFO"

if [ -n "$HEROKU_APP_NAME" ]; then
  DYNO_TAGS="$DYNO_TAGS appname:$HEROKU_APP_NAME"
fi

# Uncomment APM configs and add the log file location.
sed -i -e"s|^# apm_config:$|apm_config:|" "$DATADOG_CONF"
# Add the log file location.
sed -i -e"s|^apm_config:$|apm_config:\n  log_file: $DD_APM_LOG|" "$DATADOG_CONF"

# Uncomment the Process Agent configs and enable.
if [ "$DD_PROCESS_AGENT" == "true" ]; then
  sed -i -e"s|^# process_config:$|process_config:\n  enabled: true|" "$DATADOG_CONF"
  sed -i -e"s|^process_config:$|process_config:\n  log_file: $DD_PROC_LOG|" "$DATADOG_CONF"
fi

# Set the right path for the log collector
sed -i -e"s|^# logs_config:$|logs_config:|" "$DATADOG_CONF"
sed -i -e"s|^logs_config:$|logs_config:\n  run_path: $DD_RUN_DIR|" "$DATADOG_CONF"

# For a list of env vars to override datadog.yaml, see:
# https://github.com/DataDog/datadog-agent/blob/master/pkg/config/config.go#L145

if [ -z "$DD_API_KEY" ]; then
  echo "DD_API_KEY environment variable not set. Run: heroku config:add DD_API_KEY=<your API key>"
  DISABLE_DATADOG_AGENT=1
fi

if [ -z "$DD_HOSTNAME" ]; then
  if [ "$DD_DYNO_HOST" == "true" ]; then
    # Set the hostname to dyno name and ensure rfc1123 compliance.
    HAN="$(echo "$HEROKU_APP_NAME" | sed -e 's/[^a-zA-Z0-9-]/-/g' -e 's/^-//g')"
    if [ "$HAN" != "$HEROKU_APP_NAME" ]; then
      if [ "$DD_LOG_LEVEL_LOWER" == "debug" ]; then
        echo "WARNING: The appname \"$HEROKU_APP_NAME\" contains invalid characters. Using \"$HAN\" instead."
      fi
    fi

    D="$(echo "$DYNO" | sed -e 's/[^a-zA-Z0-9.-]/-/g' -e 's/^-//g')"
    export DD_HOSTNAME="$HAN.$D"
  else
    # Set the hostname to the dyno host
    DD_HOSTNAME="$(echo "$DYNOHOST" | sed -e 's/[^a-zA-Z0-9-]/-/g' -e 's/^-//g')"
    export DD_HOSTNAME
  fi
else
  # Generate a warning about DD_HOSTNAME deprecation.
  if [ "$DD_LOG_LEVEL_LOWER" == "debug" ]; then
    echo "WARNING: DD_HOSTNAME has been set. Setting this environment variable may result in metrics errors. To remove it, run: heroku config:unset DD_HOSTNAME"
  fi
fi

# Disable core checks (these read the host, not the dyno).
if [ "$DD_DISABLE_HOST_METRICS" == "true" ]; then
  find "$DD_CONF_DIR"/conf.d -name "conf.yaml.default" -exec mv {} {}_disabled \;
fi

# Find if the Python folder is 2 or 3
PYTHON_DIR=$(find "$DD_DIR/embedded/lib/" -maxdepth 1 -type d -name "python[2-3]\.[0-9]" -printf "%f")
DD_PYTHON_VERSION=$(echo $PYTHON_DIR | sed -n -e 's/^python\([2-3]\)\.[0-9]/\1/p')

if [ "$DD_PYTHON_VERSION" = "3" ]; then
  # This is not needed for Agent7 onwards, as it only has one Python version
  DD_AGENT_BASE_VERSION="7"
  if [ "$DD_AGENT_VERSION" != "$(echo -e "$DD_AGENT_BASE_VERSION\n$DD_AGENT_VERSION" | sort -V | head -n1)" ]; then
    # If Python version is 3, it has to be specified in the configuration file
    echo 'python_version: 3' >> $DATADOG_CONF
  fi
    # Update symlinks to Python binaries
    ln -sfn "$DD_DIR"/embedded/bin/python3 "$DD_DIR"/embedded/bin/python
    ln -sfn "$DD_DIR"/embedded/bin/python3-config "$DD_DIR"/embedded/bin/python-config
    ln -sfn "$DD_DIR"/embedded/bin/pip3 "$DD_DIR"/embedded/bin/pip
    ln -sfn "$DD_DIR"/embedded/bin/pydoc3 "$DD_DIR"/embedded/bin/pydoc
fi

# Ensure all check and library locations are findable in the Python path.
DD_PYTHONPATH="$DD_DIR/embedded/lib/$PYTHON_DIR"
DD_PYTHONPATH="$DD_PYTHONPATH:$DD_DIR/embedded/lib/$PYTHON_DIR/site-packages"
# Add other packages.
DD_PYTHONPATH="$DD_DIR/embedded/lib/$PYTHON_DIR/plat-linux2:$DD_PYTHONPATH"
DD_PYTHONPATH="$DD_DIR/embedded/lib/$PYTHON_DIR/lib-tk:$DD_PYTHONPATH"
DD_PYTHONPATH="$DD_DIR/embedded/lib/$PYTHON_DIR/lib-dynload:$DD_PYTHONPATH"
DD_PYTHONPATH="$DD_DIR/bin/agent/dist:$DD_PYTHONPATH"

#  We need to add explicitely pip and setuptools dependencies
PIP_PATH=$(find "$DD_DIR/embedded/lib/$PYTHON_DIR/site-packages" -maxdepth 1 -name "pip*egg")
SETUPTOOLS_PATH=$(find "$DD_DIR/embedded/lib/$PYTHON_DIR/site-packages" -maxdepth 1 -name "setuptools*egg")
DD_PYTHONPATH="$DD_PYTHONPATH:$SETUPTOOLS_PATH:$PIP_PATH"

# Export agent's PYTHONPATH be used by the agent-wrapper
export DD_PYTHONPATH="$DD_DIR/embedded/lib:$DD_PYTHONPATH"

# Give applications a chance to modify env vars prior to running.
# Note that this can modify existing env vars or perform other actions (e.g. modify the conf file).
# For more information on variables and other things you may wish to modify, reference this script
# and the Datadog Agent documentation: https://docs.datadoghq.com/agent
PRERUN_SCRIPT="$APP_DATADOG/prerun.sh"
if [ -e "$PRERUN_SCRIPT" ]; then
  source "$PRERUN_SCRIPT"
fi

# Convert comma delimited tags from env vars to yaml
if [ -n "$DD_TAGS" ]; then
  DD_TAGS_NORMALIZED="$(sed "s/,[ ]\?/\ /g"  <<< "$DD_TAGS")"
  DD_TAGS="$DYNO_TAGS $DD_TAGS_NORMALIZED"
else
  DD_TAGS="$DYNO_TAGS"
fi

export DD_VERSION="$DD_VERSION"
export DD_TAGS="$DD_TAGS"
if [ "$DD_LOG_LEVEL_LOWER" == "debug" ]; then
  echo "[DEBUG] Buildpack normalized tags: $DD_TAGS_NORMALIZED"
fi

DD_TAGS_YAML="tags:\n  - $(sed "s/\ /\\\n  - /g"  <<< "$DD_TAGS")"

# Inject tags after example tags.
# Config files for agent versions 6.11 and earlier:
sed -i "s/^#   - role:database$/#   - role:database\n$DD_TAGS_YAML/" "$DATADOG_CONF"
# Agent versions 6.12 and later:
sed -i "s/^\(## @param tags\)/$DD_TAGS_YAML\n\1/" "$DATADOG_CONF"

# Export host type as dyno
export DD_HEROKU_DYNO="true"

# Execute the final run logic.
if [ -n "$DISABLE_DATADOG_AGENT" ]; then
  echo "The Datadog Agent has been disabled. Unset the DISABLE_DATADOG_AGENT or set missing environment variables."
else
  # Get the Agent version number
  DATADOG_VERSION="$(expr "$(bash -c "LD_LIBRARY_PATH=\"$DD_LD_LIBRARY_PATH\" $DD_BIN_DIR/agent version")" : 'Agent \([0-9]\+\.[0-9]\+.[0-9]\+\)')"

  # Prior to Agent 6.4.1, the command is "start"
  RUN_VERSION="6.4.1"
  if [ "$DATADOG_VERSION" == "$(echo -e "$RUN_VERSION\n$DATADOG_VERSION" | sort -V | head -n1)" ]; then
    RUN_COMMAND="start"
  else
    RUN_COMMAND="run"
  fi

  # Run the Datadog Agent
  if [ "$DD_LOG_LEVEL_LOWER" == "debug" ]; then
    echo "Starting Datadog Agent on $DD_HOSTNAME"
  fi
  bash -c "PYTHONPATH=\"$DD_PYTHONPATH\" LD_LIBRARY_PATH=\"$DD_LD_LIBRARY_PATH\" $DD_BIN_DIR/agent $RUN_COMMAND -c $DATADOG_CONF 2>&1 &"

  # The Trace Agent will run by default.
  if [ "$DD_APM_ENABLED" == "false" ]; then
    if [ "$DD_LOG_LEVEL_LOWER" == "debug" ]; then
      echo "The Datadog Trace Agent has been disabled. Set DD_APM_ENABLED to true or unset it."
    fi
  else
    if [ "$DD_LOG_LEVEL_LOWER" == "debug" ]; then
      echo "Starting Datadog Trace Agent on $DD_HOSTNAME"
    fi
    bash -c "PYTHONPATH=\"$DD_PYTHONPATH\" LD_LIBRARY_PATH=\"$DD_LD_LIBRARY_PATH\" $DD_DIR/embedded/bin/trace-agent -config $DATADOG_CONF 2>&1 &"
  fi

  # The Process Agent must be run explicitly
  if [ "$DD_PROCESS_AGENT" == "true" ]; then
    if [ "$DD_LOG_LEVEL_LOWER" == "debug" ]; then
      echo "Starting Datadog Process Agent on $DD_HOSTNAME"
    fi
    bash -c "PYTHONPATH=\"$DD_PYTHONPATH\" LD_LIBRARY_PATH=\"$DD_LD_LIBRARY_PATH\" $DD_DIR/embedded/bin/process-agent -config $DATADOG_CONF 2>&1 &"
  fi
fi
