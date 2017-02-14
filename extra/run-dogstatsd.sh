#!/bin/bash

if [[ $DATADOG_API_KEY ]]; then
  sed -i -e "s/^.*api_key:.*$/api_key: ${DATADOG_API_KEY}/" /app/.apt/opt/datadog-agent/agent/datadog.conf
else
  echo "DATADOG_API_KEY environment variable not set. Run: heroku config:add DATADOG_API_KEY=<your API key>"
  exit 1
fi

if [[ $HEROKU_APP_NAME ]]; then
  sed -i -e "s/^.*hostname:.*$/hostname: ${HEROKU_APP_NAME}/" /app/.apt/opt/datadog-agent/agent/datadog.conf
else
  echo "HEROKU_APP_NAME environment variable not set. Run: heroku apps:info|grep ===|cut -d' ' -f2"
  exit 1
fi

if [[ $DATADOG_HISTOGRAM_PERCENTILES ]]; then
  sed -i -e "s/^.*histogram_percentiles:.*$/histogram_percentiles: ${DATADOG_HISTOGRAM_PERCENTILES}/" /app/.apt/opt/datadog-agent/agent/datadog.conf
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
