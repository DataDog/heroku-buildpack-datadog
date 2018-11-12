Datadog Heroku Buildpack
========================

A [Heroku buildpack](https://devcenter.heroku.com/articles/buildpacks) to add [Datadog](https://www.datadoghq.com) to a Heroku Dyno.

## Usage

This buildpack installs the Datadog Agent in your Heroku Dyno to collect system metrics, custom application metrics and traces. To collect custom application metrics or traces, include the language appropriate [DogStatsD or Datadog APM library](http://docs.datadoghq.com/libraries/) in your application.

## Installation

To add this buildpack to your project, as well as set the required environment variables:

```shell
cd <root of my project>

# If this is a new Heroku project
heroku create

# Add the appropriate language-specific buildpack. For example:
heroku buildpacks:add heroku/ruby

# Enable Heroku Labs Dyno Metadata
heroku labs:enable runtime-dyno-metadata -a $(heroku apps:info|grep ===|cut -d' ' -f2)

# Add this buildpack and set your Datadog API key
heroku buildpacks:add --index 1 https://github.com/DataDog/heroku-buildpack-datadog.git
heroku config:add DD_API_KEY=<your API key>

# Deploy to Heroku
git push heroku master
```

Once complete, the Datadog Agent is started automatically when each Dyno starts.

The Datadog Agent provides a listening port on 8125 for statsd/dogstatsd metrics and events. Traces are collected on port 8126.

## Configuration

In addition to the environment variables shown above, there are a number of others you can set:

| Setting | Description|
| --- | --- |
| `DD_API_KEY` | *Required.* Your API key is available from the [Datadog API integrations](https://app.datadoghq.com/account/settings#api) page. Note that this is the *API* key, not the application key. |
| `DD_HOSTNAME` | **WARNING**: Setting the hostname manually may result in metrics continuity errors. It is strongly recommended that you do *not* set this variable. Because dyno hosts are ephemeral it is recommended that you monitor based on the tags `dynoname` or `appname`. |
| `DD_DYNO_HOST` | *Optional.* Set to `true` to use the app and dyno name (e.g. `appname.web.1` or `appname.run.1234`) as the hostname. See the [hostname section](#hostname) below for more information. You must enable Heroku Labs Dyno Metadata to use this feature. Defaults to `false`. |
| `DD_TAGS` | *Optional.* Sets additional tags provided as a comma-delimited string. For example, `heroku config:set DD_TAGS=simple-tag-0,tag-key-1:tag-value-1`. The buildpack automatically adds the tags `dyno` (the dyno name, e.g. `web.1`) and `dynotype` (the type of dyno, e.g `run` or `web`). See the ["Guide to tagging"](http://docs.datadoghq.com/guides/tagging/) for more information. |
| `DD_HISTOGRAM_PERCENTILES` | *Optional.* Optionally set additional percentiles for your histogram metrics. See the [Histogram percentiles article](https://help.datadoghq.com/hc/en-us/articles/204588979-How-to-graph-percentiles-in-Datadog) for more information. |
| `DISABLE_DATADOG_AGENT` | *Optional.* When set, the Datadog Agent will not be run. |
| `DD_APM_ENABLED` | *Optional.* The Datadog Trace Agent (APM) is run by default. Set this to `false` to disable the Trace Agent. |
| `DD_PROCESS_AGENT` | *Optional.* The Datadog Process Agent is disabled by default. Set this to `true` to enable the Process Agent. |
| `DD_SITE` | *Optional.* If you use the app.datadoghq.eu service, set this to `datadoghq.eu`. Defaults to `datadoghq.com`. |
| `DD_AGENT_VERSION` | *Optional.* By default, the buildpack installs the latest version of the Datadog Agent available in the package repository. Use this variable to install older versions of the Datadog Agent (note that not all versions of the Agent may be available). |
| `DD_SERVICE_ENV` | *Optional.* The Datadog Agent automatically tries to identify your environment by searching for a tag in the form `env:<environment name>`. For more information, see the [Datadog Tracing environments page](https://docs.datadoghq.com/tracing/environments/). |

For additional documentation, refer to the [Datadog Agent documentation](https://docs.datadoghq.com/agent/).

## Hostname

Heroku dynos are ephemeral—they can move to different host machines whenever new code is deployed, configuration changes are made, or resouce needs/availability changes. This makes Heroku flexible and responsive, but can potentially lead to a high number of reported hosts in Datadog. Datadog bills on a per-host basis, and the buildpack default is to report actual hosts, which can lead to higher than expected costs.

Depending on your use case, you may want to set your hostname so that hosts are aggregated and report a lower number.  To do this, Set `DD_DYNO_HOST` to `true`. This will cause the Agent to report the hostname as the app and dyno name (e.g. `appname.web.1` or `appname.run.1234`) and your host count will closely match your dyno usage. One drawback is that you may see some metrics continuity errors whenever a dyno is cycled.

## Enabling integrations

You can enable Datadog Agent integrations by including an appropriately named YAML file inside a `datadog/conf.d` directory in the root of your application.

For example, to enable the [PostgreSQL integration](https://docs.datadoghq.com/integrations/postgres/), create a file `/datadog/conf.d/postgres.yaml` in your application containing:

```yaml
init_config:

instances:
  - host: <YOUR HOSTNAME>
    port: <YOUR PORT>
    username: <YOUR USERNAME>
    password: <YOUR PASSWORD>
    dbname: <YOUR DBNAME>
    ssl: True
```

During the Dyno start up, your YAML files will be copied to the appropriate Datadog Agent configuration directories.

## Prerun script

In addition to all of the configurations above, you can include a prerun script, `/datadog/prerun.sh`, in your application to arbitrarily modify the environment variables and configuration files prior to starting the Datadog Agent.

The example below demonstrates a few of the things you can do in the `prerun.sh` script:

```shell
#!/usr/bin/env bash

# Disable the Datadog Agent based on Dyno type
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

## Unsupported

Heroku buildpacks cannot be used with Docker images. To build a Docker image with Datadog, reference the [Datadog Agent docker files](https://github.com/DataDog/datadog-agent/tree/master/Dockerfiles).

It is not possible to send logs from Heroku to Datadog using this buildpack.

## Contributing

This project is open source (Apache 2 License), which means we're happy for you to fork it, but we'd be even more excited to have you contribute back to it.

### Submitting issues

* If you think you've found an issue, please search the [project issues](https://github.com/DataDog/heroku-buildpack-datadog/issues) and the [Troubleshooting](https://datadog.zendesk.com/hc/en-us/sections/200766955-Troubleshooting) section of our [Knowledge base](https://datadog.zendesk.com/hc/en-us) to see if it's known.
* If you can't find anything useful, please contact our [support team](http://docs.datadoghq.com/help/) and send a flare. To send a flare, you'll need get to your Dyno's command line:
  ```shell
  # From your project directory:
  heroku run bash

  # Once your Dyno has started and you are at the command line, send a flare:
  agent -c /app/.apt/etc/datadog-agent/datadog.yaml flare
  ```

  It can also be helpful to send logs from your running dyno:
  ```shell
  # Download Datadog Agent logs
  heroku ps:copy /app/.apt/var/log/datadog/datadog.log --dyno=<YOUR DYNO NAME>

  # Download Datadog Trace Agent logs
  heroku ps:copy /app/.apt/var/log/datadog/datadog-apm.log --dyno=<YOUR DYNO NAME>
  ```

* Finally, you can open [a Github issue](https://github.com/DataDog/heroku-buildpack-datadog/issues).

### Pull requests

Have you fixed a bug or written a new check and want to share it? Many thanks!

In order to ease/speed up our review, here are some items you can check/improve when submitting your PR:

* Keep it small and focused. Avoid changing too many things at once.
* Summarize your PR with an explanatory title and a message describing your changes. Cross-reference any related bugs/PRs and provide steps for testing when appropriate.
* Write meaningful commit messages. The commit message should describe the reason for the change and give extra details that will allow someone later on to understand in 5 seconds the thing you've been working on for a day.
* Squash your commits. Please rebase your changes on master and squash your commits whenever possible, it keeps history cleaner and it's easier to revert things.

## History

Earlier versions of this project were forked from the [miketheman heroku-buildpack-datadog project](https://github.com/miketheman/heroku-buildpack-datadog). It was largely rewritten for Datadog's Agent version 6. Changes and more information can be found in the [changelog](https://github.com/DataDog/heroku-buildpack-datadog/blob/master/CHANGELOG.md).
