#!/bin/bash

if [[ $DISABLE_DATADOG_AGENT ]]; then
  echo "DISABLE_DATADOG_AGENT environment variable is set, not starting the agent."
  exit 0
fi

if [[ $DD_API_KEY ]]; then
  sed -i -e "s/^.*api_key:.*$/api_key: ${DD_API_KEY}/" /app/.apt/opt/datadog-agent/agent/datadog.conf
else
  echo "DD_API_KEY environment variable not set. Run: heroku config:add DD_API_KEY=<your API key>"
  exit 1
fi

if [[ $HEROKU_APP_NAME ]]; then
  sed -i -e "s/^.*hostname:.*$/hostname: ${HEROKU_APP_NAME}/" /app/.apt/opt/datadog-agent/agent/datadog.conf
else
  echo "HEROKU_APP_NAME environment variable not set. Run: heroku apps:info|grep ===|cut -d' ' -f2"
  exit 1
fi

mkdir -p /tmp/logs/datadog

(
  # Unset other PYTHONPATH/PYTHONHOME variables before we start
  unset PYTHONHOME PYTHONPATH
  # Load our library path first when starting up
  export LD_LIBRARY_PATH=/app/.apt/opt/datadog-agent/embedded/lib:$LD_LIBRARY_PATH
  # Run the Datadog Agent
  exec /app/.apt/opt/datadog-agent/embedded/bin/python /app/.apt/opt/datadog-agent/agent/dogstatsd.py start
)

(
  # Run the Datadog Trace Agent
  echo "Starting Trace Agent..." >> /tmp/logs/datadog/trace-agent.log
  exec /app/.apt/opt/datadog-agent/bin/trace-agent -debug >> /tmp/logs/datadog/trace-agent.log 2>&1 &
)
