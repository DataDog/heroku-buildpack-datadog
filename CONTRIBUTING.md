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

* Finally, you can open [a GitHub issue](https://github.com/DataDog/heroku-buildpack-datadog/issues).

### Pull requests

Have you fixed a bug or written a new check and want to share it? Many thanks!

In order to ease/speed up our review, here are some items you can check/improve when submitting your PR:

* Keep it small and focused. Avoid changing too many things at once.
* Summarize your PR with an explanatory title and a message describing your changes. Cross-reference any related bugs/PRs and provide steps for testing when appropriate.
* Write meaningful commit messages. The commit message should describe the reason for the change and give extra details that will allow someone later on to understand in 5 seconds the thing you've been working on for a day.
* Squash your commits. Please rebase your changes on master and squash your commits whenever possible, it keeps history cleaner and it's easier to revert things.