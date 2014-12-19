# hubot-semaphoreapp

[Hubot](http://hubot.github.com/) script to interface with [Semaphore CI](https://www.semaphoreapp.com/).

## Installation

Add a dependency to your Hubot instance using NPM:

```bash
$ npm install --save hubot-semaphoreapp
```

Then add this script to the `external-scripts.json`:

```json
["hubot-semaphoreapp"]
```

You'll need to get an auth token from Semaphore and put it in your environment; you can find one in your project settings, under the "API" tab.
For heroku, do this:

```bash
$ heroku config:set HUBOT_SEMAPHOREAPP_AUTH_TOKEN=<token>
```

If you want the deployment commands, you'll also need to set `HUBOT_SEMAPHOREAPP_DEPLOY` to something non-zero.

## Commands

```
> hubot semaphoreapp status [<project> [<branch>]] - Reports build status for projects' branches
> hubot deploy project[/branch] [to server] - deploys project/branch to server
```
