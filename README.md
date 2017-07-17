Heroku-Datadog APM Buildpack
========================

This is a fork of Mike Fiedler's ([@miketheman](https://github.com/miketheman)) [heroku-buildpack-datadog](https://github.com/miketheman/heroku-buildpack-datadog) and adds support for the [Datadog APM](https://www.datadoghq.com/blog/announcing-apm/) agent.

Currently the Datadog APM requires its own agent, which collects trace metrics on port 7777. The Datadog Trace agent then forwards metrics to the Datadog agent on the standard StatsD/DogStatsD port 8125.

As the Datadog APM moves closer to general release, the Datadog Trace agent will be merged into the main Datadog agent. Our intention is to continue development of this buildpack until that point, then merge back into Mike's buildpack project.

## Usage

In order to use the Datadog APM, you will first need to [request Beta access].

The Datadog APM currently supports Go, Python, and Ruby (additional languages are on the roadmap). For more information about adding the language specific trace library to your application, please see the [Datadog Tracing Docs](https://app.datadoghq.com/trace/docs).

This buildpack is typically used in conjunction with other languages, so is
most useful with language-specific buildpacks. Please see [the Heroku Language Buildpacks page](https://devcenter.heroku.com/articles/buildpacks#default-buildpacks) for more information.

To instrument your application (without the APM and tracing functionality), please see [the Datadog libraries page](http://docs.datadoghq.com/libraries/).

### Installation

To add this buildpack to your project, as well as setting the required environment variables:

```shell
cd <root of my project>

heroku create # only if this is a new heroku project
heroku buildpacks:add heroku/ruby # or other language-specific build page needed
heroku buildpacks:add --index 1 https://github.com/DataDog/heroku-buildpack-datadog.git
heroku config:set DD_API_KEY=<your API key> # note: older releases called this DATADOG_API_KEY
heroku config:set DD_SERVICE_NAME=<your service name>
heroku config:set DD_SERVICE_ENV=<your service env>

git push heroku master
```

Once complete, the Datadog agent and Datadog Trace agent will be started automatically with the Dyno startup.

The Datadog agent provides a listening port on 8125 for statsd/dogstatsd metrics and events. Traces are collected on port 7777 by the Datadog Trace agent, then information is forwarded on to the Datadog Agent.

### Configuration

In addition to the environment variables shown above, there are a number of others you can set:

| Setting | Description|
| --- | --- |
| DD_API_KEY | *Required.* Your API key is available from [the Datadog API Integrations page](https://app.datadoghq.com/account/settings#api). Note that this is the *API* key, not the application key. |
| DD_SERVICE_NAME | *Optional.* While not read by the Datadog Trace agent, we highly recommend that you set an environment variable for your service name. See the [Service Name](#service-name) section below for more information. |
| DD_SERVICE_ENV | *Optional.* The Datadog Trace agent will automatically try to identify your environment by searching for a tag in the form `env:<your environment name>`. If you do not set a tag or wish to override an exsting tag, you can set the environment with this setting. For more information, see the [Datadog Tracing Docs](https://app.datadoghq.com/trace/docs/tutorials/environments). |
| DD_HOSTNAME | *Optional.* By default, the Datadog agent will report your Dyno hostname. You may use this setting to override the Dyno hostname. |
| DD_TAGS | *Optional.* Sets additional tags provided as a comma-delimited string. For example, `heroku config:set DD_TAGS=simple-tag-0,tag-key-1:tag-value-1`. See the ["Guide to tagging"](http://docs.datadoghq.com/guides/tagging/) for more information. |
| DD_HISTOGRAM_PERCENTILES | *Optional.* You can optionally set additional percentiles for your histogram metrics. See [Histogram Percentiles](#histogram-percentiles) below for more information.|
| DISABLE_DD_AGENT | *Optional.* When set, the Datadog agent and Datadog Trace agent will not be run. |

### Service name

A service is a named set of processes that do the same job, such as `webapp` or `database`. The service name provides context when evaluating your trace data.

Although the service name is passed to Datadog on the application level, we highly recommend that you set the value as an environment variable, rather than directly in your application code.

For example, set your service name as an environment variable:

```shell
heroku config:set DD_SERVICE_NAME=my-webapp
```

Then in a python web application, you could set the service name from the environment variable:

```python
import os
from ddtrace import tracer

service_nane = os.environ.get('DD_SERVICE_NAME')
span = tracer.trace("web.request", service=service_name)
...
span.finish()
```

Setting the service name will vary according to your language or supported framework. Please reference the [Datadog Tracing Integrations](https://app.datadoghq.com/trace/docs/languages) for more information.

For more information about services, see the [Datadog Tracing Terminology](https://app.datadoghq.com/trace/docs/tutorials/terminology).

### Histogram percentiles

You can optionally set additional percentiles for your histogram metrics. By default
only 95th percentile will be generated. To generate additional percentiles, set *all*
percentiles, including default one, using environment variable `DD_HISTOGRAM_PERCENTILES`.

For example, if you want to generate 0.95 and 0.99 percentiles, you may use following
command:

```shell
heroku config:add DD_HISTOGRAM_PERCENTILES="0.95, 0.99"
```

For more information about about additional percentiles, see [the  documentation](https://help.datadoghq.com/hc/en-us/articles/204588979-How-to-graph-percentiles-in-Datadog).

### Example

An example using Ruby is available at [https://github.com/miketheman/buildpack-example-ruby](https://github.com/miketheman/buildpack-example-ruby).

## Addtional information

### Rails configuration

For proper aggregation, you'll want to configure `config/initializers/datadog-tracer.rb` like so:

```
Rails.configuration.datadog_trace = {
  default_service: ENV['DD_SERVICE_NAME'] || 'my-app',
}
```

## Contributing

As mentioned, this project is a fork of the [heroku-buildpack-datadog](https://github.com/miketheman/heroku-buildpack-datadog) project and is intended to add Datadog APM support while the Datadog APM requires its own agent. Any contributions unrelated to the Datadog APM should be made upstream to that project.

If you have contributions related to the Datadog APM, please follow this process:

- Fork this repo
- Check out the code, create your own branch
- Make modifications, test heavily. Add tests if you can.
- Keep commits simple and clear. Show what, but also explain why.
- [Submit a Pull Request](https://github.com/DataDog/heroku-buildpack-datadog/pulls) from your feature branch to `master`

## License

MIT License, see `LICENSE` file for full text.
