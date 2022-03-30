#!/bin/sh

. ${BUILDPACK_TEST_RUNNER_HOME}/lib/test_utils.sh

export DD_LOG_LEVEL="debug"

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
  echo "true" > "${ENV_DIR}/DD_PROCESS_AGENT"
  echo "Testing Datadog Agent version $1"
  compile
  assertCaptured "Downloading Datadog Agent $1"
  assertCaptured "Installing Datadog Agent"
  assertCaptured "Installing Datadog runner"

  export HOME=${BUILD_DIR}
  export DD_TAGS="sampletag1:sample,sametag2:sample, sampletag3 sampletag4"
  chmod +x ${BUILDPACK_HOME}/extra/datadog.sh 
  capture ${BUILDPACK_HOME}/extra/datadog.sh
  assertFileNotContains "error while loading shared libraries" ${STD_ERR}
  assertFileNotContains "Could not initialize Python" ${STD_ERR}
  assertCaptured "Starting Datadog Agent"
  assertCaptured "Starting Datadog Trace Agent"
  assertNotCaptured "The Datadog Agent has been disabled"
  assertCaptured "[DEBUG] Buildpack normalized tags: sampletag1:sample sametag2:sample sampletag3 sampletag4"
  assertNotCaptured "ModuleNotFoundError"
  assertNotCaptured "Fatal Python error"

  
  SIZE_BIN=$(du -s  $HOME/.apt/opt/datadog-agent/bin | cut -f1)
  SIZE_LIB=$(du -s  $HOME/.apt/opt/datadog-agent/embedded/lib | cut -f1)
  SIZE_EMB_BIN=$(du -s  $HOME/.apt/opt/datadog-agent/embedded/bin | cut -f1)

  if $2; then
    assertTrue "Binary folder is too big: ${SIZE_BIN}" "[ $SIZE_BIN -lt 80000 ]"
    assertTrue "Embedded library folder is too big: ${SIZE_LIB}" "[ $SIZE_LIB -lt 180000 ]"
    assertTrue "Embedded binary folder is too big: ${SIZE_EMB_BIN}" "[ $SIZE_EMB_BIN -lt 80000 ]"
  fi

  rm -rf $HOME/.apt/
}

testReleased6Versions()
{
  echo "deb [trusted=yes] https://apt.datadoghq.com/ stable 6" > "${BUILDPACK_HOME}/etc/datadog.list"
  getAvailableVersions "datadog.list"
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
  getAvailableVersions "datadog7.list"
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
