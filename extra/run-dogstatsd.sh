#!/bin/bash

# Prefered Datadog env var name
if [[ $DD_API_KEY ]]; then
  sed -i -e "s/^[# ]*api_key:.*$/api_key: ${DD_API_KEY}/" /app/.apt/opt/datadog-agent/agent/datadog.conf
# Legacy env var support
elif [[ $DATADOG_API_KEY ]]; then
  sed -i -e "s/^[# ]*api_key:.*$/api_key: ${DATADOG_API_KEY}/" /app/.apt/opt/datadog-agent/agent/datadog.conf
else
  echo "DD_API_KEY environment variable not set. Run: heroku config:add DD_API_KEY=<your API key>"
  exit 1
fi

# Prefered Datadog env var name
if [[ $DD_HOSTNAME ]]; then
  sed -i -e "s/^[# ]*hostname:.*$/hostname: ${DD_HOSTNAME}/" /app/.apt/opt/datadog-agent/agent/datadog.conf
# Legacy env var support
elif [[ $HEROKU_APP_NAME ]]; then
  sed -i -e "s/^[# ]*hostname:.*$/hostname: ${HEROKU_APP_NAME}/" /app/.apt/opt/datadog-agent/agent/datadog.conf
else
  echo "DD_HOSTNAME environment variable not set. Run: heroku config:set DD_HOSTNAME=$(heroku apps:info|grep ===|cut -d' ' -f2)"
  exit 1
fi


if [[ $DD_APM_ENABLED ]]; then
  sed -i -e "s/^[# ]*apm_enabled:.*$/apm_enabled: true/" /app/.apt/opt/datadog-agent/agent/datadog.conf
  # Doesn't appear to have apm in the conf file. Old agent release?
  echo "apm_enabled: true" >> /app/.apt/opt/datadog-agent/agent/datadog.conf
fi

# Prefered Datadog env var name
if [[ $DD_HISTOGRAM_PERCENTILES ]]; then
  sed -i -e "s/^[# ]*histogram_percentiles:.*$/histogram_percentiles: ${DD_HISTOGRAM_PERCENTILES}/" /app/.apt/opt/datadog-agent/agent/datadog.conf
# Legacy env var support
elif [[ $DATADOG_HISTOGRAM_PERCENTILES ]]; then
  sed -i -e "s/^[# ]*histogram_percentiles:.*$/histogram_percentiles: ${DATADOG_HISTOGRAM_PERCENTILES}/" /app/.apt/opt/datadog-agent/agent/datadog.conf
fi

(
  if [[ $DISABLE_DATADOG_AGENT ]]; then
    echo "DISABLE_DATADOG_AGENT environment variable is set, not starting the agent."
  else
    # Unset other PYTHONPATH/PYTHONHOME variables before we start
    unset PYTHONHOME PYTHONPATH
    # Load our library path first when starting up
    export LD_LIBRARY_PATH=/app/.apt/opt/datadog-agent/embedded/lib:$LD_LIBRARY_PATH
    mkdir -p /tmp/logs/datadog
    exec /app/.apt/opt/datadog-agent/embedded/bin/python /app/.apt/opt/datadog-agent/agent/dogstatsd.py start
  fi
)

(
  if [[ $DISABLE_DATADOG_AGENT ]]; then
    echo "DISABLE_DATADOG_AGENT environment variable is set, not starting the tracing agent."
  else
    # Enable the trace agent
    if [[ $DD_APM_ENABLED ]]; then
      exec /app/.apt/opt/datadog-agent/bin/trace-agent -ddconfig /app/.apt/opt/datadog-agent/agent/datadog.conf >> /tmp/logs/datadog/trace-agent.log 2>&1 &
    fi
  fi
)
