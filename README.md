heroku-buildpack-datadog
========================

This is a fork of [@miketheman]'s [heroku-buildpack-datadog] and adds support for the [Datadog APM] agent.

## Usage

In order to use the Datadog APM, you will first need to [request Beta access].

This buildpack is typically used in conjunction with other languages, so is
most useful with language-specific buildpacks - see [Heroku Language Buildpacks] for more.

Here are some setup commands to add this buildpack to your project, as well as
setting the required environment variables:

```shell
cd <root of my project>

heroku create # only if this is a new heroku project
heroku buildpacks:add heroku/ruby # or other language-specific build page needed
heroku buildpacks:add --index 1 https://github.com/DataDog/heroku-buildpack-datadog.git
heroku config:set HEROKU_APP_NAME=$(heroku apps:info|grep ===|cut -d' ' -f2) 
heroku config:add DD_API_KEY=<your API key> # note: older releases called this DATADOG_API_KEY

git push heroku master
```

You can create/retrieve the `DD_API_KEY` from your account on [this page](https://app.datadoghq.com/account/settings#api).
API Key, not application key.

Once complete, the Agent's dogstatsd binary and Trace Agent binary will be started automatically with the Dyno startup.

Once started, provides a listening port on 8125 for statsd/dogstatsd metrics and events. Traces are collected on port 7777 by the Trace Agent, then information is forwarded on to the Datadog Agent.

An example using Ruby is [here](https://github.com/miketheman/buildpack-example-ruby).

## Tags
Host tags can be passed via the `DD_TAGS` environment variable
```
heroku config:set DD_TAGS=simple-tag-0,tag-key-1:tag-value-1 # to use [simple-tag-0, tag-key-1:tag-value-1] as host tags.
```

## Todo

Things that have not been tested, tried, figured out.

- see if we can bypass apt updates on every run
- determine how the compiled cache behaves with new releases of the
  datadog-agent package, as it stored the deb file
- tag release when stable, update docs on how to use a given release in
  `.buildpacks`, like "https://github.com/miketheman/heroku-buildpack-datadog.git#v1.0.0"

## Contributing

- Fork this repo
- Check out the code, create your own branch
- Make modifications, test heavily. Add tests if you can.
- Keep commits simple and clear. Show what, but also explain why.
- Submit a Pull Request from your feature branch to `master`

## Credits

This buildpack was heavily inspired by the heroku-buildpack-apt code, as well
as many others from Heroku and [@ddollar].
We leverage the same type of process runner that the Datadog Docker container
uses, with a couple of modifications.

Author: [@miketheman]

## License

MIT License, see `LICENSE` file for full text.

[Datadog]: http://www.datadog.com
[DogStatsD]: http://docs.datadoghq.com/guides/dogstatsd/
[Datadog APM]: https://www.datadoghq.com/blog/announcing-apm/
[heroku-buildpack-datadog]: https://github.com/miketheman/heroku-buildpack-datadog
[Heroku Buildpack]: https://devcenter.heroku.com/articles/buildpacks
[Heroku Language Buildpacks]: https://devcenter.heroku.com/articles/buildpacks#default-buildpacks
[request Beta access]: https://www.datadoghq.com/apm/

[@ddollar]: https://github.com/ddollar
[@miketheman]: https://github.com/miketheman
