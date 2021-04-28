# Datadog Heroku Buildpack

This [Heroku buildpack][1] installs the Datadog Agent in your Heroku dyno to collect system metrics, custom application metrics, and traces. To collect custom application metrics or traces, include the language appropriate [DogStatsD or Datadog APM library][2] in your application.

## Installation

This guide assumes that you already have your application running on Heroku. Please, refer to Heroku documentation to learn how to deploy your application to Heroku.

1. Go to [Datadog API settings][3] and copy your Datadog API key. Export it to an environment variable:

 ```shell
 export DD_API_KEY=<YOUR_API_KEY>
 ```

2. Export your application name to the APPNAME environment variable:

```shell
export APPNAME=<YOUR_HEROKU_APP_NAME>
```

3. Add the Datadog buildpack to your project:

```shell
cd <HEROKU_PROJECT_ROOT_FOLDER>

# Enable Heroku Labs Dyno Metadata to set HEROKU_APP_NAME env variable automatically
heroku labs:enable runtime-dyno-metadata -a $APPNAME

# Set hostname in Datadog as appname.dynotype.dynonumber for metrics continuity
heroku config:add DD_DYNO_HOST=true

# Add this buildpack and set your Datadog API key
heroku buildpacks:add --index 1 https://github.com/DataDog/heroku-buildpack-datadog.git
heroku config:add DD_API_KEY=$DD_API_KEY

# Deploy to Heroku forcing a rebuild
git commit --allow-empty -m "Rebuild slug"
git push heroku master
```

Once complete, the Datadog Agent is started automatically when each dyno starts.

The Datadog Agent provides a listening port on `8125` for statsd/dogstatsd metrics and events. Traces are collected on port `8126`.

### Order of buildpacks
As explained in [Heroku's documentation][4], the last buildpack in the list is used to determine the process type for the application.

Buildpacks that install apt packages (e.g. [heroku-buildpack-apt][5], [puppeteer-heroku-buildpack][6]) or buildpacks that modify the `/app` folder (e.g. [heroku-buildpack-monorepo][7]) need to be added **before** the Datadog buildpack. For example, if your application uses the `ruby`, `datadog` and `apt` buildpacks, this would be a correct `heroku buildpacks` output:

```text
1. https://github.com/heroku/heroku-buildpack-apt.git
2. https://github.com/DataDog/heroku-buildpack-datadog.git
3. heroku/ruby
```

## Pinning a specific buildpack version and a specific Datadog Agent version

Heroku recommends to always use the latest commit of a buildpack. If you need to pin the buildpack version, you can do so by specifying the buildpack release tag:

```
heroku buildpacks:add --index 1 https://github.com/DataDog/heroku-buildpack-datadog.git#<DATADOG_BUILDPACK_RELEASE>
```

Replace `<DATADOG_BUILDPACK_RELEASE>` with the [Buildpack release][8] you want to use.

By default, the buildpack pins the latest version of the Datadog Agent at the time of release. You can pin the Agent to an earlier version by setting the `DD_AGENT_VERSION` environment variable.

## Upgrading and slug recompilation

Upgrading this buildpack or modifying certain buildpack options requires you to recompile your slug.

The following options require a slug recompilation:

* `DD_AGENT_VERSION`
* `DD_AGENT_MAJOR_VERSION`
* `DD_PYTHON_VERSION`
* `DD_APM_ENABLED`
* `DD_PROCESS_AGENT`

To upgrade this buildpack and/or to change any of these options, for example `DD_AGENT_VERSION`, the following steps are required:

```shell
# Set new version of the Agent
heroku config:set DD_AGENT_VERSION=<NEW_AGENT_VERSION> -a <YOUR_APP_NAME>

# Rebuild your slug with the new Agent version:
git commit --allow-empty -m "Rebuild slug"
git push heroku master
```

## Configuration

In addition to the environment variables shown above, there are a number of others you can set:

| Setting                    | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
|----------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `DD_API_KEY`               | *Required.* Your API key is available from the [Datadog API Integrations][9] page. Note that this is the *API* key, not the application key.                                                                                                                                                                                                                                                                                                                                                                                |
| `DD_HOSTNAME`              | *Optional.* **WARNING**: Setting the hostname manually may result in metrics continuity errors. It is recommended that you do *not* set this variable. Because dyno hosts are ephemeral it is recommended that you monitor based on the tags `dynoname` or `appname`.                                                                                                                                                                                                                                                       |
| `DD_DYNO_HOST`             | *Optional.* Set to `true` to use the dyno name (e.g. `web.1` or `run.1234`) as the hostname. See the [hostname section](#hostname) below for more information. Defaults to `false`                                                                                                                                                                                                                                                                                                                                          |
| `DD_TAGS`                  | *Optional.* Sets additional tags provided as a space-separated string (**Note**: comma-separated string in buildpack versions `1.16` and earlier; this is still supported to maintain backward compatibility). For example, `heroku config:set DD_TAGS="simple-tag-0 tag-key-1:tag-value-1"`. The buildpack automatically adds the tags `dyno` which represent the dyno name (e.g. web.1) and `dynotype` (the type of dyno, e.g `run` or `web`). See the ["Guide to tagging"][10] for more information.                                                                                                                                                             |
| `DD_VERSION`                  | *Optional.* Sets the version of your application, used to organize traces by version.                                                                                                                                          |
| `DD_HISTOGRAM_PERCENTILES` | *Optional.* Optionally set additional percentiles for your histogram metrics. See [How to graph percentiles][11].                                                                                                                                                                                                                                                                                                                                                                                                            |
| `DISABLE_DATADOG_AGENT`    | *Optional.* When set, the Datadog Agent does not run.                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| `DD_APM_ENABLED`           | *Optional.* Trace collection is enabled by default. Set this to `false` to disable trace collection. Changing this option requires recompilation of the slug. Check [the upgrading and slug recompilation section](#upgrading-and-slug-recompilation) for details.                                                                                                                                                                                                                                                          |
| `DD_PROCESS_AGENT`         | *Optional.* The Datadog Process Agent is disabled by default. Set this to `true` to enable the Process Agent. Changing this option requires recompilation of the slug. Check [the upgrading and slug recompilation section](#upgrading-and-slug-recompilation) for details.                                                                                                                                                                                                                                                 |
| `DD_SITE`                  | *Optional.* If you use the app.datadoghq.eu service, set this to `datadoghq.eu`. Defaults to `datadoghq.com`.                                                                                                                                                                                                                                                                                                                                                                                                               |
| `DD_AGENT_VERSION`         | *Optional.* By default, the buildpack installs the latest 6.x version of the Datadog Agent available in the package repository. Use this variable to install older versions of the Datadog Agent (note that not all versions of the Agent may be available). This option takes precedence over `DD_AGENT_MAJOR_VERSION`. Changing this option requires recompiling the slug. Check [the upgrading and slug recompilation section](#upgrading-and-slug-recompilation) for details.                                           |
| `DD_AGENT_MAJOR_VERSION`   | *Optional.* By default, the buildpack installs the latest 6.x version of the Datadog Agent available in the package repository. Set this variable to `7` to install the latest 7.x version of the Datadog Agent. Check the [Python versions section](#python-and-agent-versions) for more information on the relation of the Agent version and Python version. Changing this option requires recompiling the slug. Check [the upgrading and slug recompilation section](#upgrading-and-slug-recompilation) for details.     |
| `DD_DISABLE_HOST_METRICS`  | *Optional.* By default, the buildpack reports system metrics for the host machine running the dyno. Set this to `true` to disable system metrics collection. See the [system metrics section](#system-metrics) below for more information.                                                                                                                                                                                                                                                                                  |
| `DD_PYTHON_VERSION`        | *Optional.* Starting with version `6.14.0`, Datadog Agent ships with Python versions `2` and `3`. The buildpack only keeps one of the versions. Set this to `2` or `3` to select the Python version you want the Agent to keep. If not set, the buildpack keeps `2`. Check the [Python versions section](#python-and-agent-versions) for more information. Changing this option requires recompiling the slug. Check [the upgrading and slug recompilation section](#upgrading-and-slug-recompilation) for details. |
| `DD_HEROKU_CONF_FOLDER`    | *Optional.* By default, the buildpack looks in the root of your application for a folder `/datadog` for any configuration files you wish to include, eg see [prerun.sh script](#prerun-script). This location can be overridden by setting this to your desired path. |

For additional documentation, refer to the [Datadog Agent documentation][12].

## Hostname

Heroku dynos are ephemeral—they can move to different host machines whenever new code is deployed, configuration changes are made, or resouce needs/availability changes. This makes Heroku flexible and responsive, but can potentially lead to a high number of reported hosts in Datadog. Datadog bills on a per-host basis, and the buildpack default is to report actual hosts, which can lead to higher than expected costs.

Depending on your use case, you may want to set your hostname so that hosts are aggregated and report a lower number. To do this, Set `DD_DYNO_HOST` to `true`. This causes the Agent to report the hostname as the app and dyno name (for example `appname.web.1` or `appname.run.1234`) and your host count will closely match your dyno usage. One drawback is that you may see some metrics continuity errors whenever a dyno is cycled.

For this to work correctly, `HEROKU_APP_NAME` needs to be set. The easiest way to do this is by [enabling dyno metadata][13]. **Note**: Dyno metadata is not yet available in Private Spaces, in which case you need to set `HEROKU_APP_NAME` manually.

## System metrics

By default, the buildpack collects system metrics for the host machine running your dyno. System metrics are not available for individual dynos using this buildpack. To disable host system metrics collection, set the `DD_DISABLE_HOST_METRICS` environment variable to `true`.

In order to collect system metrics for your dynos, you must:

1. Enable the [Heroku Labs: log-runtime-metrics][14].
2. Use the [Datadog log drain][15] to collect metric logs from the Heroku Logplex and forward them to Datadog.
3. Generate [log-based metric][16] over the collected logs.

## File locations

* The Datadog Agent is installed at `/app/.apt/opt/datadog-agent`
* The Datadog Agent configuration files are at `/app/.apt/etc/datadog-agent`
* The Datadog Agent logs are at `/app/.apt/var/log/datadog`

## Enabling integrations

To enable a [Datadog-<INTEGRATION_NAME> integration][17], create a file in the datadog configuration folder within your application. During the dyno start up, your YAML files are copied to the appropriate Datadog Agent configuration directories.

For example, to enable the [Datadog-Redis integration][18], add the file `/datadog/conf.d/redisdb.yaml` at the root of your application (or `/$DD_HEROKU_CONF_FOLDER/conf.d/redisdb.yaml` if you have changed this [configuration option](#configuration)):

```yaml
init_config:

instances:

    ## @param host - string - required
    ## Enter the host to connect to.
    #
  - host: <REDIS_HOST>

    ## @param port - integer - required
    ## Enter the port of the host to connect to.
    #
    port: 6379
```

**Note**: See the sample [redisdb.d/conf.yaml][19] for all available configuration options.

If the integration you are enabling is part of the [Community Integrations][20], install the package as part of the [prerun script](#prerun-script).

```
agent-wrapper integration install -t datadog-<INTEGRATION_NAME>==<INTEGRATION_VERSION>
```

For example, to install the [ping integration][21], create the configuration file `datadog/conf.d/ping.yaml` and add the following line to your prerun script:

```
agent-wrapper integration install -t datadog-ping==1.0.0
```

## Prerun script

In addition to all of the configurations above, you can include a prerun script, `/datadog/prerun.sh`, in your application. The prerun script runs after all of the standard configuration actions and immediately before starting the Datadog Agent. This allows you to modify the environment variables (for example, DD_TAGS or DD_VERSION), perform additional configurations, install community integrations, or even disable the Datadog Agent programmatically.

The example below demonstrates a few of the things you can do in the `prerun.sh` script:

```shell
#!/usr/bin/env bash

# Disable the Datadog Agent based on dyno type
if [ "$DYNOTYPE" == "run" ]; then
  DISABLE_DATADOG_AGENT="true"
fi

# Set app version based on HEROKU_SLUG_COMMIT
if [ -n "$HEROKU_SLUG_COMMIT" ]; then
  DD_VERSION=$HEROKU_SLUG_COMMIT
fi

# Update the Postgres configuration from above using the Heroku application environment variable
if [ -n "$DATABASE_URL" ]; then
  POSTGREGEX='^postgres://([^:]+):([^@]+)@([^:]+):([^/]+)/(.*)$'
  if [[ $DATABASE_URL =~ $POSTGREGEX ]]; then
    sed -i "s/<YOUR HOSTNAME>/${BASH_REMATCH[3]}/" "$DD_HEROKU_CONF_FOLDER/conf.d/postgres.d/conf.yaml"
    sed -i "s/<YOUR USERNAME>/${BASH_REMATCH[1]}/" "$DD_HEROKU_CONF_FOLDER/conf.d/postgres.d/conf.yaml"
    sed -i "s/<YOUR PASSWORD>/${BASH_REMATCH[2]}/" "$DD_HEROKU_CONF_FOLDER/conf.d/postgres.d/conf.yaml"
    sed -i "s/<YOUR PORT>/${BASH_REMATCH[4]}/" "$DD_HEROKU_CONF_FOLDER/conf.d/postgres.d/conf.yaml"
    sed -i "s/<YOUR DBNAME>/${BASH_REMATCH[5]}/" "$DD_HEROKU_CONF_FOLDER/conf.d/postgres.d/conf.yaml"
  fi
fi

# Install the "ping" community integration
agent-wrapper integration install -t datadog-ping==1.0.0
```

## Limiting Datadog's console output

In some cases, you may want to limit the amount of logs the Datadog buildpack is writing to the console.

To limit the log output of the buildpack, set the `DD_LOG_LEVEL` environment variable to one of the following: `TRACE`, `DEBUG`, `INFO`, `WARN`, `ERROR`, `CRITICAL`, `OFF`.

```shell
heroku config:add DD_LOG_LEVEL=ERROR
```

## Optional binaries

To save slug space, the `trace-agent` and `process-agent` optional binaries are removed during compilation if `DD_APM_ENABLED` is set to `false`, and/or `DD_PROCESS_AGENT` is not set or set to `false`.

To reduce your slug size, make sure that `DD_APM_ENABLED` is set to `false`, if you are not using APM features; and `DD_PROCESS_AGENT` is not set to `true`, if you are not using process monitoring.

## Debugging

To run any of the information/debugging commands listed in the [Agent's documentation][22] use the `agent-wrapper` command.

For example, to display the status of your Datadog Agent and enabled integrations, run:

```shell
agent-wrapper status
```

## Python and Agent versions

Prior to version `6.14` the Datadog v6 Agent shipped with Python version `2` embedded. Starting with `6.14`, and in preparation for Python version `2` End Of Life, announced for January 2020, the Datadog v6 Agent ships with both Python versions `2` and `3`, to give customers enough time to migrate their custom checks to Python version `3`. The Heroku buildpack only keeps one of the versions. Set `DD_PYTHON_VERSION` to `2` or `3` to select the Python version you want the Agent to keep. If not set, the buildpack keeps Python version `2`. If you are using custom checks that only work with Python version `2`, we recommend to migrate them to version `3` before its EOL.

Agent v7 only ships with Python version `3`. If you are not using custom checks or your custom checks are already migrated to version `3`, we recommend moving to Agent 7 as soon as possible. Starting with `6.15`, v7 releases with the same minor version share the same feature set, making it safe to move between those two. For example, if you are running `6.16` and you don't need Python version `2`, it is safe to jump to `7.16`.

## Heroku log collection

The Datadog buildpack does not collect logs from the Heroku platform. To set up Heroku log collection, see the [dedicated guide][15].

## Using Heroku with Docker images

This buildpack only works for Heroku deployments that use [Heroku's Slug Compiler][23]. If you are deploying your application in Heroku using Docker containers, add the Datadog Agent as part of your Docker image and start the Agent as a different process in your container.

As an example, if you are building your Docker image using a Debian based OS, add the following lines to your `Dockerfile`:

```
# Install GPG dependencies
RUN apt-get update \
 && apt-get install -y gpg apt-transport-https gpg-agent curl ca-certificates

# Add Datadog repository and signing keys
RUN sh -c "echo 'deb https://apt.datadoghq.com/ stable 7' > /etc/apt/sources.list.d/datadog.list"
RUN apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 A2923DFF56EDA6E76E55E492D3A80E30382E94DE
RUN apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 D75CEA17048B9ACBF186794B32637D44F14F620E

# Install the Datadog Agent
RUN apt-get update && apt-get -y --force-yes install --reinstall datadog-agent

# Copy entrypoint
COPY entrypoint.sh /

# Expose DogStatsD and trace-agent ports
EXPOSE 8125/udp 8126/tcp

# Copy your Datadog configuration
COPY datadog-config/ /etc/datadog-agent/

CMD ["/entrypoint.sh"]
```

In your Docker container entry point, start the Datadog Agent, Datadog APM Agent, and Datadog Process Agent:

```
#!/bin/bash

datadog-agent run &
/opt/datadog-agent/embedded/bin/trace-agent --config=/etc/datadog-agent/datadog.yaml &
/opt/datadog-agent/embedded/bin/process-agent --config=/etc/datadog-agent/datadog.yaml
```

For more advanced options in the Docker image, reference the [Datadog Agent Docker files][24].

## Contributing

See the [contributing documentation][25] to learn how to open an issue or PR to the [Heroku-buildpack-datadog repository][26].

## History

Earlier versions of this project were forked from the [miketheman heroku-buildpack-datadog project][27]. It was largely rewritten for Datadog's Agent version 6. Changes and more information can be found in the [changelog][28].

## Troubleshooting

### Datadog is reporting a higher number of agents than dynos

Make sure you have `DD_DYNO_HOST` set to `true` and that `HEROKU_APP_NAME` has a value set for every Heroku application. See the [Hostname section](#hostname) for details.

### After upgrading the buildpack or the Agent, the Agent is reporting errors when starting up

After an upgrade of the buildpack or Agent, you must recompile your application's slug. Check [the upgrading and slug recompilation section](#upgrading-and-slug-recompilation) for details.

[1]: https://devcenter.heroku.com/articles/buildpacks
[2]: https://docs.datadoghq.com/libraries
[3]: https://app.datadoghq.com/account/settings#api
[4]: https://devcenter.heroku.com/articles/using-multiple-buildpacks-for-an-app#viewing-buildpacks
[5]: https://github.com/heroku/heroku-buildpack-apt
[6]: https://github.com/jontewks/puppeteer-heroku-buildpack
[7]: https://github.com/lstoll/heroku-buildpack-monorepo
[8]: https://github.com/DataDog/heroku-buildpack-datadog/releases
[9]: https://app.datadoghq.com/account/settings#api
[10]: https://docs.datadoghq.com/tagging/
[11]: https://docs.datadoghq.com/dashboards/guide/how-to-graph-percentiles-in-datadog/
[12]: https://docs.datadoghq.com/agent
[13]: https://devcenter.heroku.com/articles/dyno-metadata
[14]: https://devcenter.heroku.com/articles/log-runtime-metrics
[15]: https://docs.datadoghq.com/logs/guide/collect-heroku-logs
[16]: https://docs.datadoghq.com/logs/logs_to_metrics/
[17]: https://docs.datadoghq.com/integrations/
[18]: https://docs.datadoghq.com/integrations/redisdb/
[19]: https://github.com/DataDog/integrations-core/blob/master/redisdb/datadog_checks/redisdb/data/conf.yaml.example
[20]: https://github.com/DataDog/integrations-extras/
[21]: https://github.com/DataDog/integrations-extras/tree/master/ping
[22]: https://docs.datadoghq.com/agent/guide/agent-commands/#agent-status-and-information
[23]: https://devcenter.heroku.com/articles/slug-compiler
[24]: https://github.com/DataDog/datadog-agent/tree/master/Dockerfiles
[25]: https://github.com/DataDog/heroku-buildpack-datadog/blob/master/CONTRIBUTING.md
[26]: https://github.com/DataDog/heroku-buildpack-datadog
[27]: https://github.com/miketheman/heroku-buildpack-datadog
[28]: https://github.com/DataDog/heroku-buildpack-datadog/blob/master/CHANGELOG.md
