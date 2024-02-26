#!/bin/sh

. ${BUILDPACK_HOME}/test/common.sh

export DD_LOG_LEVEL="debug"

testReleased6Versions()
{
  echo "deb [trusted=yes] https://apt.datadoghq.com/ stable 6" > "${BUILDPACK_HOME}/etc/datadog.list"
  getAvailableVersions "datadog.list" 5
  echo "deb [signed-by=SIGNED_BY_PLACEHOLDER] https://apt.datadoghq.com/ stable 6" > "${BUILDPACK_HOME}/etc/datadog.list"

  for VERSION in ${AGENT_VERSIONS}; do
    # Only test for size from 6.34 onwards
    if test "6.34.0-1" = "$(echo "6.34.0-1\n$VERSION" | sort -V | head -n1)" ; then
      compileAndRunVersion $VERSION true
    else
      compileAndRunVersion $VERSION false
    fi
  done
}

testReleased7Versions()
{
  echo "deb [trusted=yes] https://apt.datadoghq.com/ stable 7" > "${BUILDPACK_HOME}/etc/datadog7.list"
  getAvailableVersions "datadog7.list" 5
  echo "deb [signed-by=SIGNED_BY_PLACEHOLDER] https://apt.datadoghq.com/ stable 7" > "${BUILDPACK_HOME}/etc/datadog7.list"

  for VERSION in ${AGENT_VERSIONS}; do
    # Only test for size from 7.34 onwards
    if test "7.34.0-1" = "$(echo "7.34.0-1\n$VERSION" | sort -V | head -n1)" ; then
      compileAndRunVersion $VERSION true
    else
      compileAndRunVersion $VERSION false
    fi
  done
}

