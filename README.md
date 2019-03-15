---
title: Datadog Heroku Buildpack
kind: documentation
aliases:
- /developers/faq/how-do-i-collect-metrics-from-heroku-with-datadog
---

This [Heroku buildpack][1] installs the Datadog Agent in your Heroku dyno to collect system metrics, custom application metrics, and traces. To collect custom application metrics or traces, include the language appropriate [DogStatsD or Datadog APM library][2] in your application.

## Installation

To add this buildpack to your project, as well as set the required environment variables:

```shell
cd <HEROKU_PROJECT_ROOT_FOLDER>

# If this is a new Heroku project
heroku create

# Add the appropriate language-specific buildpack. For example:
heroku buildpacks:add heroku/ruby

# Enable Heroku Labs Dyno Metadata
heroku labs:enable runtime-dyno-metadata -a $(heroku apps:info|grep ===|cut -d' ' -f2)

# Add this buildpack and set your Datadog API key
heroku buildpacks:add --index 1 https://github.com/DataDog/heroku-buildpack-datadog.git
heroku config:add DD_API_KEY=<DATADOG_API_KEY>

# Deploy to Heroku
git push heroku master
```

Replace `<DATADOG_API_KEY>` with your [Datadog API key][3].

Once complete, the Datadog Agent is started automatically when each dyno starts.

The Datadog Agent provides a listening port on `8125` for statsd/dogstatsd metrics and events. Traces are collected on port `8126`.

## Configuration

In addition to the environment variables shown above, there are a number of others you can set:

| Setting                      | Description|
| ---------------------------- | ------------------------------ |
| `DD_API_KEY`                 | *Required.* Your API key is available from the [Datadog API Integrations][4] page. Note that this is the *API* key, not the application key.|
| `DD_HOSTNAME`                | *Optional.* **WARNING**: Setting the hostname manually may result in metrics continuity errors. It is recommended that you do *not* set this variable. Because dyno hosts are ephemeral it is recommended that you monitor based on the tags `dynoname` or `appname`.|
| `DD_DYNO_HOST`               | *Optional.* Set to `true` to use the dyno name (e.g. `web.1` or `run.1234`) as the hostname. See the [hostname section](#hostname) below for more information. Defaults to `false`|
| `DD_TAGS`                    | *Optional.* Sets additional tags provided as a space-delimited string. For example, `heroku config:set DD_TAGS="simple-tag-0 tag-key-1:tag-value-1"`. The buildpack automatically adds the tags `dyno` and `dynohost` which represent the dyno name (e.g. web.1) and host ID (e.g. 33f232db-7fa7-461e-b623-18e60944f44f) respectively. See the ["Guide to tagging"][5] for more information.|
| `DD_HISTOGRAM_PERCENTILES`   | *Optional.* Optionally set additional percentiles for your histogram metrics. See [How to graph percentiles][6].|
| `DISABLE_DATADOG_AGENT`      | *Optional.* When set, the Datadog Agent does not run.|
| `DD_APM_ENABLED`             | *Optional.* Trace collection is enabled by default. Set this to `false` to disable trace collection.|
| `DD_PROCESS_AGENT`           | *Optional.* The Datadog Process Agent is disabled by default. Set this to `true` to enable the Process Agent.|
| `DD_SITE`                    | *Optional.* If you use the app.datadoghq.eu service, set this to `datadoghq.eu`. Defaults to `datadoghq.com`.|
| `DD_AGENT_VERSION`           | *Optional.* By default, the buildpack installs the latest version of the Datadog Agent available in the package repository. Use this variable to install older versions of the Datadog Agent (note that not all versions of the Agent may be available).|
| `DD_DISABLE_HOST_METRICS`    | *Optional.* By default, the buildpack reports system metrics for the host machine running the dyno. Set this to `true` to disable system metrics collection. See the [system metrics section](#system-metrics) below for more information.|

For additional documentation, refer to the [Datadog Agent documentation][9].

## Hostname

Heroku dynos are ephemeral—they can move to different host machines whenever new code is deployed, configuration changes are made, or resouce needs/availability changes. This makes Heroku flexible and responsive, but can potentially lead to a high number of reported hosts in Datadog. Datadog bills on a per-host basis, and the buildpack default is to report actual hosts, which can lead to higher than expected costs.

Depending on your use case, you may want to set your hostname so that hosts are aggregated and report a lower number.  To do this, Set `DD_DYNO_HOST` to `true`. This will cause the Agent to report the hostname as the app and dyno name (e.g. `appname.web.1` or `appname.run.1234`) and your host count will closely match your dyno usage. One drawback is that you may see some metrics continuity errors whenever a dyno is cycled.

## System metrics

By default, the buildpack collects system metrics for the host machine running your dyno. System metrics are not available for individual dynos using this buildpack. To disable host system metrics collection, set the `DD_DISABLE_HOST_METRICS` environment variable to `true`.

In order to collect system metrics for your dynos, use a log drain to collect metric logs from the Heroku Logplex and forward them to Datadog. See the [community integrations documentation][17] for a list of community supported log drains.

## File locations

- The Datadog Agent is installed at `/app/.apt/opt/datadog-agent`
- The Datadog Agent configuration files are at `/app/.apt/etc/datadog-agent`
- The Datadog Agent logs are at `/app/.apt/var/log/datadog`

## Enabling integrations

You can enable Datadog Agent integrations by including an appropriately named YAML file inside a `datadog/conf.d` directory in the root of your application.

For example, to enable the [PostgreSQL integration][10], create a file `/datadog/conf.d/postgres.yaml` in your application containing:

```
init_config:

instances:
  - host: <YOUR HOSTNAME>
    port: <YOUR PORT>
    username: <YOUR USERNAME>
    password: <YOUR PASSWORD>
    dbname: <YOUR DBNAME>
    ssl: True
```

During the dyno start up, your YAML files are copied to the appropriate Datadog Agent configuration directories.

## Prerun script

In addition to all of the configurations above, you can include a prerun script, `/datadog/prerun.sh`, in your application. The prerun script will run after all of the standard configuration actions and immediately before starting the Datadog Agent. This allows you to modify the environment variables, perform additional configurations, or even disable the Datadog Agent programmatically.

The example below demonstrates a few of the things you can do in the `prerun.sh` script:

```shell
#!/usr/bin/env bash

# Disable the Datadog Agent based on dyno type
if [ "$DYNOTYPE" == "run" ]; then
  DISABLE_DATADOG_AGENT="true"
fi

# Update the Postgres configuration from above using the Heroku application environment variable
if [ -n "$DATABASE_URL" ]; then
  POSTGREGEX='^postgres://([^:]+):([^@]+)@([^:]+):([^/]+)/(.*)$'
  if [[ $DATABASE_URL =~ $POSTGREGEX ]]; then
    sed -i "s/<YOUR HOSTNAME>/${BASH_REMATCH[3]}/" "$DD_CONF_DIR/conf.d/postgres.d/conf.yaml"
    sed -i "s/<YOUR USERNAME>/${BASH_REMATCH[1]}/" "$DD_CONF_DIR/conf.d/postgres.d/conf.yaml"
    sed -i "s/<YOUR PASSWORD>/${BASH_REMATCH[2]}/" "$DD_CONF_DIR/conf.d/postgres.d/conf.yaml"
    sed -i "s/<YOUR PORT>/${BASH_REMATCH[4]}/" "$DD_CONF_DIR/conf.d/postgres.d/conf.yaml"
    sed -i "s/<YOUR DBNAME>/${BASH_REMATCH[5]}/" "$DD_CONF_DIR/conf.d/postgres.d/conf.yaml"
  fi
fi
```

## Limiting Datadog's console output

In some cases, you may want to limit the amount of logs the Datadog buildpack is writing to the console.

To limit the log output of the buildpack, set the `DD_LOG_LEVEL` environment variable to one of the following: `TRACE`, `DEBUG`, `INFO`, `WARN`, `ERROR`, `CRITICAL`, `OFF`.

```
heroku config:add DD_LOG_LEVEL=ERROR
```

## Heroku log collection

The Heroku Datadog buildpack does not collect logs. To set up log collection, see the [dedicated guide][16].

## Unsupported

Heroku buildpacks cannot be used with Docker images. To build a Docker image with Datadog, reference the [Datadog Agent Docker files][12].

## Contributing

See the [contributing documentation][13] to learn how to open an issue or PR to the Heroku-buildpack-datadog repository[13].

## History

Earlier versions of this project were forked from the [miketheman heroku-buildpack-datadog project][14]. It was largely rewritten for Datadog's Agent version 6. Changes and more information can be found in the [changelog][15].

[1]: https://devcenter.heroku.com/articles/buildpacks
[2]: https://docs.datadoghq.com/libraries
[3]: https://app.datadoghq.com/account/settings#api
[4]: https://app.datadoghq.com/account/settings#api
[5]: https://docs.datadoghq.com/tagging
[6]: /graphing/faq/how-to-graph-percentiles-in-datadog
[8]: https://docs.datadoghq.com/tracing/setup/?tab=agent630#trace-search
[9]: https://docs.datadoghq.com/agent
[10]: https://docs.datadoghq.com/integrations/postgres
[11]: https://devcenter.heroku.com/articles/log-drains#https-drains
[12]: https://github.com/DataDog/datadog-agent/tree/master/Dockerfiles
[13]: https://github.com/DataDog/heroku-buildpack-datadog/blob/master/CONTRIBUTING.md
[14]: https://github.com/miketheman/heroku-buildpack-datadog
[15]: https://github.com/DataDog/heroku-buildpack-datadog/blob/master/CHANGELOG.md
[16]: https://docs.datadoghq.com/logs/guide/collect-heroku-logs
[17]: https://docs.datadoghq.com/developers/libraries/#heroku
