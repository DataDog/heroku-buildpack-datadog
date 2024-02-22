#!/bin/sh

. ./common.sh

export DD_LOG_LEVEL="debug"

testLatest6NightlyVersion()
{
  echo "deb [trusted=yes] http://apt.datad0g.com/ nightly 6" > "${BUILDPACK_HOME}/etc/datadog.list"
  getAvailableVersions "datadog.list"
  VERSION="$(echo ${AGENT_VERSIONS} | head -n1 | awk '{print $1;}')"

  compileAndRunVersion $VERSION
}

testLatest7NightlyVersion()
{
  echo "deb [trusted=yes] http://apt.datad0g.com/ nightly 7" > "${BUILDPACK_HOME}/etc/datadog7.list"
  getAvailableVersions "datadog7.list"
  VERSION="$(echo ${AGENT_VERSIONS} | head -n1 | awk '{print $1;}')"

  compileAndRunVersion $VERSION
}
