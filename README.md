[![Build Status](https://travis-ci.com/cyfronet-fid/marketplace.svg?branch=master)](https://travis-ci.com/cyfronet-fid/marketplace)

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

### Running parametrized database seeds 
While running `/bin/setup` rake will seed the database with important data. However seeds can 
also be re-run with additional parameters allowing to specify e.g. number of services seeded
to the database.
 
Example use of the database seed:
```
rake db:seed services_size=100
```

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

## JIRA

Marketplace is integrating with jira on a rather tight level. 
For tests JIRA is stubbed, and for normal development it can be omitted,
but in case there is a need for JIRA instance to exist it is recommeded
to use jira instance provided by atlassian SDK.

Here are instructions how to install atlassian SDK on *nix systems:
https://developer.atlassian.com/server/framework/atlassian-sdk/install-the-atlassian-sdk-on-a-linux-or-mac-system/

After installation you can start local JIRA instance by

```
atlas-run-standalone --product jira --server localhost
```

Afterwards JIRA can be accessed by the browser on http://localhost:2990/jira
default username and password is: `admin/admin`.
Make sure that environmental variables are set as follows (if you don't know some
ids skip it for now, `rails jira:check` will give you sensible hints, `.dotenv` gem should be active
in the development environment, so you can store following variables in `.env` file in the root of the project):

```
export MP_JIRA_PROJECT=MP 
export MP_JIRA_USERNAME=admin
export MP_JIRA_PASSWORD=admin
export MP_JIRA_CONTEXT_PATH=/jira
export MP_JIRA_URL=http://localhost:2990
export MP_JIRA_ISSUE_TYPE_ID=10000  #this might be different
export MP_JIRA_WF_TODO=10000  #this might be different
export MP_JIRA_WF_IN_PROGRESS=10001  #this might be different
export MP_JIRA_WF_IN_DONE=10002  #this might be different
export MP_HOST="http://localhost:5000" # this is address of MP application
```

Afterwards you should run rake task which will check JIRA connection and will detect potential problems

```
rails jira:check
```

If you run fresh jira instance you can also create project by running
```
rails jira:setup
```

### Webhooks

As of now webhooks must be created manually. You can do it in your administrator
panel on your JIRA instance.

Webhook url must be as follows `<MP HOSTNAME e.g. http://localhost:2990>/api/webhooks/jira`.
JQL for querying should be: `project = <PROJECT_KEY>`
All notifications for issues and comments should be enabled.

If you create webhook, but are not sure whether options you have choosen are correct
running
```
rails jira:check
```
will show you all problems with your webhook, including notifications you should have
checked on. (**NOTICE:** don't forget to set you ENV variables correctly (see above),
especially `MP_HOST` variable, without it rake task will not be able to identify which
webhook is pointing to your application)


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
  * `ELASTICSEARCH_URL` - elasticsearch url   


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

## Database

By default we are using pure rails database configuration in development and
test enironemnts (sockets and database login the same as your system login).
If this is not enough you can customize it by using environment variables:
  * `MP_DATABASE_HOST` - PostgreSQL database host
  * `MP_DATABASE_USERNAME` - PostgreSQL database username
  * `MP_DATABASE_PASSWORD` - PostgreSQL database password

## Environmental Variables

This project can be further customized via numerous environmental variables.
To make storing them a little easier `dotenv` gem has been employed.
You can read documentation [here](https://github.com/bkeepers/dotenv).

In shourt you can store your env variables in `.env` file in the root of the project.

