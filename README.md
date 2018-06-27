[![Build Status](https://travis-ci.org/cyfronet-fid/marketplace.svg?branch=master)](https://travis-ci.org/cyfronet-fid/marketplace)

# README

Market place is...

## Development environment

### Requirements

We will need:
  * ruby (specific version can be found in [.tool-versions](.tool-versions)).
    Recommented way to manage ruby versions is to use [asdf](https://github.com/asdf-vm/asdf)
    with [asdf-ruby](https://github.com/asdf-vm/asdf-ruby) plugin
  * nodejs (specific version can be found in [.tool-versions](.tool-versions)).
    Recommented way to manage nodejs versions is to use [asdf](https://github.com/asdf-vm/asdf)
    with [asdf-nodejs](https://github.com/asdf-vm/asdf-nodejs) plugin.
  * [postgresql](https://www.postgresql.org)

### Setup

  * First time run `/bin/setup`. It will install bundler, foreman,
    dependencies and setup databases (development and test).
  * After update run `/bin/update`. It will update dependencies, run db
    migrations and restart currently started application.

### Generating DB entries for development
To simplify development `dev:prime` rake task is created. Right now it generates
services with random title and description (this generation is done using
`faker` gem). In the future this task will be extended with additional data.

```
rails dev:prime     # Remove existing services and generate 100 new services
rails dev:prime[50] # Remove existing services and generate 50 new services
```

## Elasticserach
Elasticsearch is used for full text service search.

On Debian/Ubuntu/Mint Elasticsearch installation is quite simple
(but it doesn't always work, see below):
```
sudo apt-get install elasticsearch
```

The version included in ubuntu 16.04 and 17.10 is buggy and outdated, so it should be
installed manually through deb file as described below.

If your disto does not include this package use [instructions from
elasticsearch.org](https://www.elastic.co/guide/en/elastic-stack/current/index.html).

Use `service` command to control the server:
```
sudo service elasticsearch start
```
or you can also use `systemctl`, it shouldn't matter which one you use.

-In order to inspect it you can use
 -[ElasticHQ](http://www.elastichq.org/gettingstarted.html) (plugin option is
 -quick and easy).

## Run

To start web application in development mode (with auto refresh capability when
css/js files change) use following command:

```
./bin/server
```

By default application should start on [http://localhost:5000](). You can change
port by setting ENV variable `PORT`.

## Sentry integration

In production environment sentry integration can be turned on. To do so create
dedicated env variable `SENTRY_DSN` with details how to connect to sentry
server. Sentry environment can also be configured using `SENTRY_ENVIRONMENT`
env variable (default set to `production`).

## ENV variables

We are using ENV variables to customize application. You can set the following
ENV variables:

  * `PORT` (Optional) - http server port (default 5000)
  * `CHECKIN_HOST` (Optional) - checkin IDP host (default `aai-dev.egi.eu`)
  * `ROOT_URL` (Optional) - root application URL (default
    `http://localhost:#{ENV["PORT"] || 3000}` (when foreman is used to start
    application 5000 ENV variable is set)


## Commits

Running `bin/setuo` automatically installs githooks for code linting. But if you're using
an IDE for repository management then you will probably experience problems with commiting
code changes. This is related to the fact that some IDE's do not inherit user's `.bash_profile`
or any other scripts which traditionally set environmental variables.

Installed githooks require access to ruby, so ruby environment must be available for IDE.

For Jetbrains IDE some solutions can be found (here)[https://emmanuelbernard.com/blog/2012/05/09/setting-global-variables-intellij/]

For OSX solution might be calling `sudo launchctl config user path $PATH`
For Linux systems modifying `PATH` in `/etc/environment` should do the job.

## Designing UI without dedicated controller

If there is no view yet implemented than still designing team can play around
and create `haml`, `scss`, `js` for this view. For this purpose `playground`
section is created. It is available **ONLY** in development mode. The URL is
`/playground/:file`, where `:file` is the name of the view created in
`app/views/playground` directory. For example `/playground/profile` URL will
render `app/views/playground/profile.html.haml` file.

Since this is only for development there is no security and template
existence checks.
