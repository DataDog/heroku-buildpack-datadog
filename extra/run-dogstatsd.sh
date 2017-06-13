#!/bin/bash

DD_AGENT_CONF="/app/.apt/opt/datadog-agent/agent/datadog.conf"

# Prefered Datadog env var name
if [[ $DD_API_KEY ]]; then
  sed -i -e "s/^[# ]*api_key:.*$/api_key: ${DD_API_KEY}/" $DD_AGENT_CONF
# Legacy env var support
elif [[ $DATADOG_API_KEY ]]; then
  sed -i -e "s/^[# ]*api_key:.*$/api_key: ${DATADOG_API_KEY}/" $DD_AGENT_CONF
else
  echo "DD_API_KEY environment variable not set. Run: heroku config:add DD_API_KEY=<your API key>"
  DISABLE_DATADOG_AGENT=1
fi

# Prefered Datadog env var name
if [[ $DD_HOSTNAME ]]; then
  sed -i -e "s/^[# ]*hostname:.*$/hostname: ${DD_HOSTNAME}/" $DD_AGENT_CONF
# Legacy env var support
elif [[ $HEROKU_APP_NAME ]]; then
  sed -i -e "s/^[# ]*hostname:.*$/hostname: ${HEROKU_APP_NAME}/" $DD_AGENT_CONF
else
  echo "DD_HOSTNAME environment variable not set. Run: heroku config:set DD_HOSTNAME=$(heroku apps:info|grep ===|cut -d' ' -f2)"
  DISABLE_DATADOG_AGENT=1
fi


if [[ $DD_APM_ENABLED ]]; then
  sed -i -e "s/^[# ]*apm_enabled:.*$/apm_enabled: true/" $DD_AGENT_CONF
fi

# Prefered Datadog env var name
if [[ $DD_HISTOGRAM_PERCENTILES ]]; then
  sed -i -e "s/^[# ]*histogram_percentiles:.*$/histogram_percentiles: ${DD_HISTOGRAM_PERCENTILES}/" $DD_AGENT_CONF
# Legacy env var support
elif [[ $DATADOG_HISTOGRAM_PERCENTILES ]]; then
  sed -i -e "s/^[# ]*histogram_percentiles:.*$/histogram_percentiles: ${DATADOG_HISTOGRAM_PERCENTILES}/" $DD_AGENT_CONF
fi

# Enable Developer Mode
sed -i -e "s/^[# ]*developer_mode:.*$/developer_mode: yes/" $DD_AGENT_CONF

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
      exec /app/.apt/opt/datadog-agent/bin/trace-agent -ddconfig $DD_AGENT_CONF >> /tmp/logs/datadog/trace-agent.log 2>&1 &
    fi
  fi
)
