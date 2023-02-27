# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [2.9] - 2023-02-27

### Added
- Datadog agent pinned versions are now `6.43.0` and `7.43.0`
- Redis and Postgres integrations can be now configured setting an environment variable, without using the prerun.sh script.

### Deprecated
- This is the last buildpack version with Datadog Agent 6.x as default. Upgrade today to Datadog Agent 7.x by setting the environment variable `DD_AGENT_MAJOR_VERSION=7` in your Heroku application and rebuilding the slug.

## [2.8] - 2023-01-25

### Removed
- Installing checks with `agent-wrapper integration install` is no longer supported for Datadog Agent 6.x.\
Upgrade to Datadog Agent 7.x by setting the environment variable `DD_AGENT_MAJOR_VERSION=7` in your Heroku application and rebuilding the slug.

### Added
- Datadog agent pinned versions are now `6.42.0` and `7.42.0`

## [2.7] - 2022-12-22

### Added
- Datadog agent pinned versions are now `6.41.1` and `7.41.1`

## [2.6] - 2022-11-09

### Added
- Datadog agent pinned versions are now `6.40.0` and `7.40.0`
- Config files for integrations now can follow the same folder structure used in the Agent

### Fixed
- Slug size now doesn't increae when apt buildpack is used (Thanks caioariede for the contribution!)

## [2.5] - 2022-09-13

### Added
- Datadog agent pinned versions are now `6.39.0` and `7.39.0`
- Added warning message when removing the APM or process agent

## [2.4] - 2022-07-27

### Added
- Datadog agent pinned versions are now `6.38.0` and `7.38.0`

### Fixed
- Removed new introduced unneeded binaries that were increasing the footprint

## [2.3] - 2022-07-15

### Added
- Datadog agent pinned versions are now `6.37.1` and `7.37.1`

## [2.2] - 2022-05-25

### Added
- Datadog agent pinned versions are now `6.36.0` and `7.36.0`

## [2.1] - 2022-04-25

### Added
- Datadog agent pinned versions are now `6.35.1` and `7.35.1`

## [2.0] - 2022-03-02

### Added
- Specific Heroku Datadog Agent build (starting with `6.34.0` and `7.34.0`) is now used
- Datadog agent pinned versions are now `6.34.0` and `7.34.0`

### Fixed
- Community integrations can now be installed properly when the Python versions for the agent and the system are different

## [1.33] - 2022-01-27

### Added
- Datadog agent pinned versions are now `6.33.0` and `7.33.0`
- Custom checks are now easier to set up. (https://docs.datadoghq.com/agent/basic_agent_usage/heroku/#enabling-custom-checks)

## [1.32] - 2021-12-27

### Security
- Agents `6.32.4` and `7.32.4` remove all dependencies on log4j and use java.util.logging instead.

### Added
- Datadog agent pinned versions are now `6.32.4` and `7.32.4`

## [1.31] - 2021-12-16

### Security

-  Agents `6.32.3` and `7.33.3` upgrade the log4j dependency to 2.12.2 in JMXFetch to fully address [CVE-2021-44228](https://nvd.nist.gov/vuln/detail/CVE-2021-44228) and [CVE-2021-45046](https://nvd.nist.gov/vuln/detail/CVE-2021-45046)

### Added
- Datadog agent pinned versions are now `6.32.3` and `7.32.3`

## [1.30] - 2021-12-13

### Security
- Agents `6.32.2` and `7.32.2` set `-Dlog4j2.formatMsgNoLookups=True` when starting the JMXfetch process to mitigate the vulnerability described in [CVE-2021-44228](https://nvd.nist.gov/vuln/detail/CVE-2021-44228)

### Added
- Datadog agent pinned versions are now `6.32.2` and `7.32.2`

## [1.29] - 2021-09-23

### Added
- Datadog agent pinned versions are now `6.31.0` and `7.31.0`

## [1.28] - 2021-07-01

### Fixed
- Fixed memcached integration for Python 3

## [1.27] - 2021-06-28

### Added
- Datadog agent pinned versions are now `6.29.0` and `7.29.0`
- The Dyno ID is now sent as host alias (requires Agent 6.29.0/7.29.0 or newer)

## [1.26] - 2021-05-28

### Added
- Datadog agent pinned versions are now `6.28.0` and `7.28.0`

### Changed
- Apt signing keys are now obtained from keys.datadoghq.com

## [1.25] - 2021-04-19

### Added
- Datadog agent pinned versions are now `6.27.0` and `7.27.0`

### Fixed
- HTTPS repo fetching

## [1.24] - 2021-03-03

### Added
- Datadog agent pinned versions are now `6.26.0` and `7.26.0`
- Datadog configuration path can now be configured with the `DD_HEROKU_CONF_FOLDER` environment variable

## [1.23] - 2021-01-20

### Added
- Datadog agent pinned versions are now `6.25.0` and `7.25.0`
- Heroku APT cache is now cleaned up automatically when DD_AGENT_VERSION changes

## [1.22] - 2020-12-09

### Added
- Datadog agent pinned versions are now `6.24.0` and `7.24.0`
- Heroku APT cache is now cleaned up when changing stacks
- Heroku-20 stack is now supported

### Removed
- Removed Datadog agent unneeded dependencies

## [1.21] - 2020-10-09

### Added
- Datadog agent pinned versions are now `6.23.0` and `7.23.0`

### Change
- Buildpack name reported by `bin/detect` is now "Datadog" instead of "Sysstat"

## [1.20] - 2020-09-09

### Changed
- Removed the security-agent and system-probe dependencies to reduce slug size

### Fixed
- version-history.json is now created successfully, even if DD_LOGS_ENABLED="false"

## [1.19] - 2020-08-27

### Changed
- Agent now reports `datadog.heroku_agent.running` metric instead of `datadog.agent.running` for agent versions `6/7.22` and newer, to help customers identify which agents are reporting from a Heroku dyno.

### Fixed
- Buildpack now works correctly with agent versions 7.21.x

### Added
- Datadog agent pinned versions are now `6.22.0` and `7.22.0`
- DD_VERSION can now be set as part of the `prerun.sh` script

## [1.18] - 2020-06-17

### Added
- Datadog agent pinned versions are now `6.20.2` and `7.20.2`

## [1.17] - 2020-05-04

### Added
- Datadog agent pinned versions are now `6.19.0` and `7.19.0`
- Added documentation around running Docker in Heroku
- DD_TAGS now support space separated tags
- DD_TAGS can now be modified in the pre-run script

## [1.16] - 2020-03-18

### Added
- Datadog agent pinned versions are now `6.18.0` and `7.18.0`

### Fixed
- DD_LOG_LEVEL is now honored for all agents

## [1.15] - 2020-02-07

### Added
- Datadog agent pinned versions are now `6.17.0` and `7.17.0`

## [1.14] - 2020-01-22

### Added
- Datadog agent pinned versions are now `6.16.1` and `7.16.1`

### Fixed
- Fixed `run_path` for the logs collector

## [1.13] - 2019-12-18

### Added
- Datadog's buildpack now supports Agent versions 7.16 forward
- Datadog agent pinned versions are now `6.16.0` and `7.16.0`

## [1.12] - 2019-12-13

### Added
- Datadog agent pinned version is now `6.15.1`
- Added a deprecation warning if users are using Python 2 in 6.x.

### Fixed
- Fixed `datadog.sh` to run correctly in flynn.io.

## [1.11] - 2019-12-05

### Added

- Added `buildpackversion` tag with the version of the buildpack.
- Documentation section about rebuilding slugs when modifying certain options.
- Documenation about the order for slug layers.

### Fixed
- Fixed `mcache` integration for python 2.

### Changed
- Documentation on how to collect system metrics from the dynos.

## [1.10] - 2019-10-22

### Added

- `agent-wrapper` binary. This executable bash script will be added to the `PATH` when starting a dyno using Datadog's buildpack to help running agent's debugging/status commands.

### Changed
- `LD_LIBRARY_PATH` in `datadog.sh` is not exported anymore, to avoid conflicts with Heroku's runtime
- Compilation linking paths are not exported anymore

## [1.9] - 2019-10-08

### Added
- Slug size reduction:

  The buildpack now removes the `process-agent` and `trace-agent` agent binaries, if the user has process monitoring and/or APM disabled on their configuration, to reduce slug size. Added documentation.
- Improved `hostname` related documentation

### Removed
- To reduce the slug size, the buildpack removes some libraries not used in a Heroku environment:
  * `kubernetes`
  * `openstack`
  * `pysnmp_mibs`
  * `pyVim` and `pyVmomi`

## [1.8] - 2019-09-23

### Added
- Datadog agent pinned version is now `6.14.0`
- Added unit tests for the buildpack

### Changed
- The environment variable to select the python version is now `DD_PYTHON_VERSION`. Added documentation about this

### Fixed
- Fixed `start` command deprecation (#126)

## [1.7] - 2019-08-30

### Added
- Datadog agent versions are now pinned to a specific version if `DD_AGENT_VERSION` is not set (currently 6.13.0)
- For versions 6.14 onwards, agent ships with both Python2 and Python3. Set `PYTHON_VERSION` to "2" or "3" to select the version of the Python runtime.

### Fixed
- Fixed `DD_TAGS` documentation

## [1.6.5] - 2019-07-31
Merged PR from @dirk to fix tag injection for Agent 6.12+

### Added
- 6.12 changed the template config file format. This release adds a new regex to maintain tag injection.

## [1.6.4] - 2019-07-08
Fixed the python path generation code.

### Changed
- Python path generation for embedded python site packages has been updated for Agent 6.12 release.

## [1.6.3] - 2019-06-28
Fixed the python path generation code.

### Changed
- Python path generation for embedded python site packages has been updated for Agent 6.12 release.

## [1.6.2] - 2019-02-28
When pinning Datadog Agent versions, previous buildpacks pulled old versions from the buildpack cache causing availability to be unreliable. The buildpack now pulls old versions from apt.

### Changed
- The buildpack now pulls old versions from apt.
- Updated documentation around system metrics.

## [1.6.1] - 2019-02-05
Fixed the python path generation code. In between 1.6.0 and 1.6.1 the buildpack added trace search configs to the `datadog.yaml` file. This has been removed as support for the `DD_APM_ANALYZED_SPANS` environment variable is directly supported by the Agent.

### Changed
- Python path generation for embedded python site packages has been fixed.

## [1.6.0] - 2018-11-08
Updated the run script to provide a better way for users to arbitrarily modify the environment and configurations.

### Added
- Added prerun.sh support so users can modify the environment and configurations
- Added appropriate documentation. Thanks to abtreece for the postgres auto config idea!

### Changed
- Updated the way python_path is built to be more reliable (uses find instead of ls)
- Updated the postgres integration documentation to include more details, including ssl enabling (required by hosted Heroku postgres)

## [1.5.0] - 2018-08-27
External keyservers were becoming an issue for reliability so the Datadog public key has been added to the buildpack. A few updates were made regarding Agent versioning and the documentation was clarified.

### Added
- Added the Datadog public PGP key.
- Invalid pinned versions of the Datadog Agent now returns a list of valid options.

### Changed
- Now uses the included PGP key to validate the Datadog package
- Datadog Agent from version 6.4.1 now uses the `run` command. Previous versions will still use `start`

## [1.4.1] - 2018-08-20
Thanks to pawelchcki for spotting that the integration support lacked a check if no integration files existed. This update fixes an issue where the Datadog Trace Agent may fail to start or drop traces.

### Added
- A small check to ensure integration configuration files exist when running logic to import them.

## [1.4.0] - 2018-07-31
Thanks to lucasm-iRonin for adding functionality to support Datadog Agent integrations!

### Changed
- Now using sks-keyservers instead of ubuntu keyservers. This should increase reliability

### Added
- Basic Datadog Agent integration support.

### Removed
- Removed docs referencing Datadog documentation site. That site will soon pull from this repo.

## [1.3.4] - 2018-06-11
Thanks to dreid for help resolving the apt-key issue, fixing compatibility with the Heroku-18 stack.

### Changed
- Fixed apt-key issue, buildpack compatibility with Heroku-18 stack.
- Fixed PYTHONPATH issue preventing python-based core integrations from running.
- Set APM log location resulting in log location related errors. APM log is now at /app/.apt/etc/datadog/datadog-apm.log

## [1.3.3] - 2018-06-01

### Changed
- Removed dynohost tag

## [1.3.2] - 2018-05-21
Hostnames are not always RFC1123 compliant. Invalid hostnames led to unexpected non-reporting.

### Changed
- Updated documentation to mention enabling Heroku Labs metadata (required for DD_DYNO_HOST)

### Added
- Added a check for non-compliant hostnames. Buildpack will rename and throw a warning

## [1.3.1] - 2018-04-26
Using dyno name as hostname was not properly namespaced, so multiple apps would have dyno hostname collisions. Appname has been added to prevent this.

### Changed
- DD_DYNO_HOST reports hosts as appname.dynoname.

## [1.3.0] - 2018-04-24
Fixed an issue where custom tags completely override the built-in tags for dyno information. Added a switch to change the hostname from host to dyno. This will provide some flexibility and control in how you are billed by Datadog.

### Changed
- DD_TAGS will now merge with other tags set by the buildpack, rather than overriding them.

### Added
- DD_DYNO_HOST will allow you to set the agent hostname to the dyno name, rather than host.
- Added a tag for dynotype.

## [1.2.0] - 2018-04-11
Changed buildpack to use dyno hostnames rather than setting the application name as the hostname. Though the previous method helped simplify continuity, it led to metrics aggregation errors for applications running many dynos. The application name is now available under the "appname" tag when Heroku Labs Dyno Metadata is enabled or the "HEROKU_APP_NAME" environment variable is set.

### Changed
- Hostname will default to dyno host name, unless DD_HOSTNAME is set (not recommended)

### Added
- Application name added as "appname" tag.

### Removed
- Removed README documentation about histogram percentiles and APM that were not specific to the buildpack. See https://docs.datadoghq.com for information about those features.

## [1.1.0] - 2018-03-15
Start the Trace Agent.

### Changed
- Removed Trace Agent config file code. The Trace Agent now uses the main datadog.yaml file.
- Updated the README file to document DD_APM_ENABLED.

### Added
- Datadog Agent 6 no longer starts the Trace Agent (was moved to systemd service for Linux systems). Added code to start the Trace Agent.

## [1.0.1] - 2018-03-02
Resolved issue with dpkg and multiple packages available

### Changed
- Includes a fix from Zunda that limits the dpkg install to the latest package.

## [1.0.0] - 2018-02-28
Updated the buildpack to use stable releases and removed alpha flag (because nobody really knows what that means anyway ;))

### Changed
- Updated the apt repo to use `stable 6` (no longer beta)
- Incorporates a parameter change that resolved problems in beta rc releases (Thanks Zunda!)

## [1.0.0-alpha2] - 2018-02-05
Mostly fixes and a small feature.

### Added
- If no Datadog Agent version has been pinned, the build process will tell you how to pin the current version.

### Changed
- Updated the runner script to insert tags in the correct location in the conf file.
- Env vars are not automatically loaded when building slugs, so the previous version pinning didn't work.

## [1.0.0-alpha1] - 2017-11-21
The buildpack was re-written to use the new Datadog Agent 6 and gather full system metrics.

### Added
- Added an Apache 2 license.
- Added a notice file with copyright info.
- Added a way to pin Datadog Agent versions.
- Added a changelog.
- Added a more comprehensive "Contributing" section to the readme.

### Changed
- Updated from the Datadag Agent 5 to Agent 6. This includes the main agent and the trace agent.

### Removed
- Deprecated env vars that no longer apply in Agent 6

## [legacy] - 2017-11-21
Note that the previous Agent-5-based version of the buildpack is now available using the `legacy` tag.
To continue using this old version, you can update your app by running:
```shell
# Remove the old untagged buildpack
heroku buildpacks:remove https://github.com/DataDog/heroku-buildpack-datadog.git
# Add the tagged version of the buildpack
heroku buildpacks:add --index 1 https://github.com/DataDog/heroku-buildpack-datadog.git#legacy
```
