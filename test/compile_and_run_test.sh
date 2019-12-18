#!/bin/sh

. ${BUILDPACK_TEST_RUNNER_HOME}/lib/test_utils.sh


getAvailableVersions()
{
  APT_DIR="$HOME/.apt" APT_CACHE_DIR="$CACHE_DIR/apt/cache"
  APT_STATE_DIR="$CACHE_DIR/apt/state"
  mkdir -p "$APT_CACHE_DIR/archives/partial"
  mkdir -p "$APT_STATE_DIR/lists/partial"
  mkdir -p "$APT_DIR"
  APT_REPO_FILE="${BUILDPACK_HOME}/etc/${1}"
  APT_OPTIONS="-o debug::nolocking=true -o dir::cache=$APT_CACHE_DIR -o dir::state=$APT_STATE_DIR -o Dir::Etc::SourceList=$APT_REPO_FILE"
  apt-get $APT_OPTIONS update
  AGENT_VERSIONS=$(apt-cache $APT_OPTIONS show datadog-agent | grep "Version: " | sed 's/Version: 1://g')
}

compileAndRunVersion()
{

  echo $1 > "${ENV_DIR}/DD_AGENT_VERSION"
  echo "Testing Datadog Agent version $1"
  compile
  assertCaptured "Installing dependencies"
  assertCaptured "Downloading Datadog Agent $1"
  assertCaptured "Installing Datadog Agent"
  assertCaptured "Installing Datadog runner"

  export HOME=${BUILD_DIR}
  chmod +x ${BUILDPACK_HOME}/extra/datadog.sh 
  capture ${BUILDPACK_HOME}/extra/datadog.sh
  assertFileNotContains "error while loading shared libraries" ${STD_ERR}
  assertFileNotContains "Could not initialize Python" ${STD_ERR}
  assertCaptured "Starting Datadog Agent"
  assertCaptured "Starting Datadog Trace Agent"
  assertNotCaptured "The Datadog Agent has been disabled"

}

testReleased6Versions()
{
  getAvailableVersions "datadog.list"

  for VERSION in ${AGENT_VERSIONS}; do
    compileAndRunVersion $VERSION
  done 
}

testReleased7Versions()
{
  getAvailableVersions "datadog7.list"

  for VERSION in ${AGENT_VERSIONS}; do
    compileAndRunVersion $VERSION
  done
}

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
