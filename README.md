heroku-buildpack-datadog
========================

A [Heroku Buildpack] to add [Datadog] [DogStatsD] and [APM] to any Dyno.

## Usage

This buildpack collects [DogStatsD] metrics emited by applications and sends them to your Datadog account. To instrument your application, use the language-appropriate [Datadog library] and add the corresponding [Heroku Language Buildpack].

The Datadog [APM] currently supports Go, Python, and Ruby (additional languages are on the roadmap). For more information about adding the language specific trace library to your application, please see the [Datadog Tracing Docs]. Note that the Datadog APM is an additional product and may not be included in your account.

### Installation

To add this buildpack to your project, as well as setting the required environment variables:

```shell
cd <root of my project>

# If this is a new Heroku project
heroku create

# Add the appropriate language-specific buildpack
heroku buildpacks:add heroku/ruby

# Add this buildpack and set your environment variables
heroku buildpacks:add --index 1 https://github.com/miketheman/heroku-buildpack-datadog.git
heroku config:set DD_HOSTNAME=$(heroku apps:info|grep ===|cut -d' ' -f2)
heroku config:add DD_API_KEY=<your API key>

# To enable APM tracing, run the following
heroku config:set DD_APM_ENABLED=true

# Deploy to Heroku
git push heroku master
```

Once complete, the Datadog agent (and optionally the Datadog APM tracing agent) will be started automatically with the Dyno startup.

The Datadog agent provides a listening port on 8125 for statsd/dogstatsd metrics and events. Traces are collected on port 8126 (older Datadog tracing libraries may use port 7777).

### Configuration

In addition to the environment variables shown above, there are a number of others you can set:

| Setting | Description|
| --- | --- |
| DD_API_KEY | *Required.* Your API key is available from [the Datadog API Integrations page]. Note that this is the *API* key, not the application key. |
| DD_HOSTNAME | *Optional.* By default, the Datadog agent will report your Dyno hostname. You may use this setting to override the Dyno hostname. |
| DD_TAGS | *Optional.* Sets additional tags provided as a comma-delimited string. For example, `heroku config:set DD_TAGS=simple-tag-0,tag-key-1:tag-value-1`. See the ["Guide to tagging"] for more information. |
| DD_HISTOGRAM_PERCENTILES | *Optional.* You can optionally set additional percentiles for your histogram metrics. See [Histogram Percentiles](#histogram-percentiles) below for more information.|
| DISABLE_DATADOG_AGENT | *Optional.* When set, the Datadog agent and Datadog Trace agent will not be run. |
| DD_APM_ENABLED | *Optional.* When set, this will start the Datadog Trace agent. |
| DD_APM_DEBUG | *Optional.* When set, this will enable debug logging. Log information is available by running `heroku logs`. |
| DD_SERVICE_NAME | *Optional.* While not read directly by the Datadog Trace agent, we highly recommend that you set an environment variable for your service name. See the [Service Name](#service-name) section below for more information. |
| DD_SERVICE_ENV | *Optional.* The Datadog Trace agent will automatically try to identify your environment by searching for a tag in the form `env:<your environment name>`. If you do not set a tag or wish to override an exsting tag, you can set the environment with this setting. For more information, see the [Datadog Tracing environments page]. |

### Histogram percentiles

You can optionally set additional percentiles for your histogram metrics. By default only 95th percentile will be generated. To generate additional percentiles, set *all* persentiles, including default one, using env variable `DATADOG_HISTOGRAM_PERCENTILES`.  For example, if you want to generate 0.95 and 0.99 percentiles, you may use following command:

```shell
heroku config:add DATADOG_HISTOGRAM_PERCENTILES="0.95, 0.99"
```

For more information about about additional percentiles, see [the percentiles documentation].

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

For Ruby on Rails applications, you'll need to configure the `config/initializers/datadog-tracer.rb` file:

```ruby
Rails.configuration.datadog_trace = {
  default_service: ENV['DD_SERVICE_NAME'] || 'my-app',
}
```

Setting the service name will vary according to your language or supported framework. Please reference the [Datadog Tracing Integrations] for more information.

For more information about services, see the [Datadog Tracing Terminology page].

### Example

An example using Ruby is available at [https://github.com/miketheman/buildpack-example-ruby].

## Todo

Things that have not been tested, tried, figured out.

- see if we can bypass apt updates on every run
- determine how the compiled cache behaves with new releases of the datadog-agent package, as it stored the deb file
- tag release when stable, update docs on how to use a given release in `.buildpacks`, like "https://github.com/miketheman/heroku-buildpack-datadog.git#v1.0.0"

## Contributing

- Fork this repo
- Check out the code, create your own branch
- Make modifications, test heavily. Add tests if you can.
- Keep commits simple and clear. Show what, but also explain why.
- Submit a Pull Request from your feature branch to `master`

## Credits

This buildpack was heavily inspired by the heroku-buildpack-apt code, as well as many others from Heroku and [@ddollar].
We leverage the same type of process runner that the Datadog Docker container uses, with a couple of modifications.

Author: [@miketheman]

## License

MIT License, see `LICENSE` file for full text.

[Heroku Buildpack]: https://devcenter.heroku.com/articles/buildpacks
[Datadog]: http://www.datadog.com
[DogStatsD]: http://docs.datadoghq.com/guides/dogstatsd/
[APM]: https://www.datadoghq.com/apm/
[Datadog library]: http://docs.datadoghq.com/libraries/
[Heroku Language Buildpack]: https://devcenter.heroku.com/articles/buildpacks#default-buildpacks
[Datadog Tracing Docs]: https://app.datadoghq.com/trace/docs
[the Datadog API Integrations page]: https://app.datadoghq.com/account/settings#api
["Guide to tagging"]: http://docs.datadoghq.com/guides/tagging/
[Datadog Tracing environments page]: https://app.datadoghq.com/trace/docs/tutorials/environments
[the percentiles documentation]: https://help.datadoghq.com/hc/en-us/articles/204588979-How-to-graph-percentiles-in-Datadog
[Datadog Tracing Integrations]: https://app.datadoghq.com/trace/docs/languages
[Datadog Tracing Terminology page]: https://app.datadoghq.com/trace/docs/tutorials/terminology

[@ddollar]: https://github.com/ddollar
[@miketheman]: https://github.com/miketheman
