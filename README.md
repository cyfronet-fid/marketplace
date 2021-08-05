![Build Status](https://github.com/cyfronet-fid/marketplace/actions/workflows/ci.yml/badge.svg?branch=master)
![Build Status](https://github.com/cyfronet-fid/marketplace/actions/workflows/e2e.yml/badge.svg?branch=master)

# README

Marketplace is a place where you can find resources you need for your research:
  * free of charge resources for researchers
  * unified order management
  * compatible resources linking to ready to use environments

## Development environment

### Requirements

We will need:
  * ruby (specific version can be found in [.tool-versions](.tool-versions)).
    Recommended way to manage ruby versions is to use [asdf](https://github.com/asdf-vm/asdf)
    with [asdf-ruby](https://github.com/asdf-vm/asdf-ruby) plugin
  * nodejs (specific version can be found in [.tool-versions](.tool-versions)).
    Recommended way to manage nodejs versions is to use [asdf](https://github.com/asdf-vm/asdf)
    with [asdf-nodejs](https://github.com/asdf-vm/asdf-nodejs) plugin.
  * elasticsearch (specific version can be found in [.tool-versions](.tool-versions)).
    Recommended way to manage elasticsearch versions is to use [asdf](https://github.com/asdf-vm/asdf)
    with [asdf-elasticsearch](https://github.com/asdf-community/asdf-elasticsearch) plugin.
  * [postgresql](https://www.postgresql.org)
  * [redis](https://redis.io)
  * [yarn](https://classic.yarnpkg.com/en/docs/install#debian-stable)

If you are using [asdf](https://github.com/asdf-vm/asdf) the easiest way to
install required ruby, nodejs and elasticsearch version is to type

```
asdf install
```

in marketplace root directory. Ruby and nodejs versions will be set in automatic
way. To start correct elasticsearch version type `elasticsearch` in the
marketplace root directory.

### Setup
Before running `./bin/setup` you need to:
  * create file `config/master.key` with appropriate content in order to make `config/credentials.yml.enc` decryptable.
  * setup postgres <system_username> role with SUPERUSER and CREATEDB privileges (see [database section](#database))
  * run elasticsearch server in the background (described in the [section below](#elasticsearch))

To set up the environment run `./bin/setup`. It will install bundler, foreman, 
dependencies and setup databases (development and test).

### Generating DB entries for development
Filling the database is done by parsing yaml: `db/data.yml`.
Data comes from the actual official version of the marketplace.
If you want to update the data or add new resources/categories, you can add new records by editing `db/data.yml`.
It is important to remember that if some record is a parent for another, it must be written above its child.

If necessary, there is an other option to fill the database:
To simplify development `dev:prime` rake task is created. Right now it generates
resources with random names and descriptions (this generation is done using
`faker` gem). In the future this task will be extended with additional data.

```
./bin/rails dev:prime     # Remove existing resources and generate 100 new resources
./bin/rails dev:prime[50] # Remove existing resources and generate 50 new resources
```

If you need actual production data run:
```
./bin/rake import:vocabularies
./bin/rake import:providers
./bin/rake import:resources
```
to seed the database with it.
You can download only specific providers/resources by setting an `IDS` environment variable.

## Run
To start web application in development mode (with auto refresh capability when
css/js files change) use following command:

```
./bin/server
```
It uses foreman and start processes defined in `Procfile.dev`.
Script also checks if [overmind](https://github.com/DarthSim/overmind)
is present in the classpath and uses it instead of `foreman`.
`overmind` is more advanced than `foreman` and plays nicely with e.g. `byebug`.

> Currently there is a problem with stopping overmind process when sidekiq is
> used in versions [2.1.1 and 2.1.0](https://github.com/DarthSim/overmind/issues/76) -
> use `2.0.3` instead.

By default application should start on [http://localhost:5000](). You can change
port by setting [env variable](#environmental-variables) `PORT`. You also need to run 
[elasticsearch](#elasticsearch) and [redis](#redis) in the background before starting the application server.

## Elasticsearch
Elasticsearch is used for full text resource search.

If you installed elasticsearch using asdf, run this command in the marketplace root directory:
```
elasticsearch --daemonize --pidfile <pidfile_path> 
```
It will run elasticsearch server in the background, on the default port (9200) 
and record the pid of the server to the <pidfile_path>.

To shut down the server run:
```
pkill -F <pidfile_path> 
```
... or just shut down your OS.


Alternatively, you can install elasticsearch on Debian/Ubuntu/Mint:
(but it doesn't always work, see below):
```
sudo apt-get install elasticsearch
```

The version included in ubuntu 16.04 and 17.10 is buggy and outdated, so it should be
installed manually through deb file as described below.

If your distro does not include this package use [instructions from
elasticsearch.org](https://www.elastic.co/guide/en/elastic-stack/current/index.html).

Use `service` command to control the server:
```
sudo service elasticsearch start
```
or you can also use `systemctl`, it shouldn't matter which one you use.

-In order to inspect it you can use
 -[ElasticHQ](http://www.elastichq.org/gettingstarted.html) (plugin option is
 -quick and easy).

## Redis

Marketplace uses [redis](https://redis.io) server to run jobs in the background. 
After installing it, run the server with:
```
redis-server
```
...which will start the server on default port (6379).

## JIRA

Marketplace is integrating with jira on a rather tight level.
For tests JIRA is mocked, and for normal development connection from MP to JIRA is provided.
All fields and JIRA variables are stored in encrypted credentials. The default project to which
issues are written is `EOSCSODEV`. If you require backward communication from JIRA to your application
you can use reverse tunnel to connect WH to your local application instance. To do so execute following command
(first make sure that your local instance of marketplace has been started already):

```
ssh -R <port_number - from 9001 to 9015>:localhost:5000 mszostak@docker-fid.grid.cyf-kr.edu.pl -N
```

If you can not connect, try different port - it is possible that other developer connected
to this port and is blocking it

## XGUS

Marketplace is integrated with xGUS Helpdesk.
All variables needed to establish a connection to the test instance are stored in encrypted credentials.
To run integration test there is a need to type `rake xgus:check` in the console.
To run on different than test instance, there is a need do set [env variables](#environmental-variables):
- `MP_XGUS_USERNAME`
- `MP_XGUS_PASSWORD`
- `MP_XGUS_WSDL`

## Google Analytics API

Marketplace has integration with Google Analytics and shows users with executive roles resources unique visits counter.
Default period is 1 month,

## ReCaptcha

ReCaptcha is now used in the ask resource question form. To work it needs to set 2 
[env variables](#environmental-variables):
`RECAPTCHA_SITE_KEY` and `RECAPTCHA_SECRET_KEY`. For test, development and internal docker instances
values of these variables are stored in encrypted credentials.

## For Admins

If you are an admin, who wants to integrate production instance of JIRA go to
[JIRA integration manual](./docs/jira_integration.md) otherwise read on.

Additionally there is HD / Feedback mechanism implemented using JIRA collectors.
In order to enable it in production following environmental variable should be set:

* `JIRA_COLLECTOR_SCRIPTS`

This variable should be set to the address of script (or scripts - space separated) which are generated when
configuring JIRA collector in JIRA instance. Sample declaration of this variable can be as follows (for two scripts)

Note the space separating both scripts sources

```
JIRA_COLLECTOR_SCRIPTS="https://jira.example.com/s/xxx-CDN/xx/00/xxx/x.x.x.x/_/download/batch/com.atlassian.plugins.jquery:jquery/com.atlassian.plugins.jquery:jquery.js?collectorId=00000 https://jira.example.com/s/xxx/xxx/0/xxx/x.x.x/_/download/batch/com.atlassian.jira.collector.plugin.jira-issue-collector-plugin:issuecollector/com.atlassian.jira.collector.plugin.jira-issue-collector-plugin:issuecollector.js?locale=en-UK&collectorId=yyyyy"
```

## Sentry integration

In production environment sentry integration can be turned on. To do so create
dedicated [env variable](#environmental-variables) `SENTRY_DSN` with details how to connect to sentry
server. Sentry environment can also be configured using `SENTRY_ENVIRONMENT`
[env variable](#environmental-variables) (default set to `production`).

## New relic integration

Newrelic rpm gem is added into `production` dependencies. The only thing you
need to do to turn newrelic on production is to get `newrelic.yml` and put it
into rails root directory.

## Environmental variables

This project can be customized via numerous environmental variables.
To make storing them a little easier `dotenv` gem has been employed.
You can read documentation [here](https://github.com/bkeepers/dotenv).

You can store your env variables in `.env` file in the root of the project. 
You can then access them in ruby code via:
```
ENV[VAR]
```

We are currently using the following ENV variables:

  * `MP_VERSION` (Optional) - the application's version (default taken from the file `./VERSION`)
  * `PORT` (Optional) - http server port (default 5000)
  * `CHECKIN_HOST` (Optional) - checkin IDP host (default `aai-dev.egi.eu`)
  * `CHECKIN_IDENTIFIER` (Optional) - checkin IDP identifier (default taken from
    encrypted properties)
  * `CHECKIN_SECRET` (Optional) - checkin IDP secret (default taken from
    encrypted properties)
  * `ROOT_URL` (Optional) - root application URL (default
    `http://localhost:#{ENV["PORT"] || 3000}` (when foreman is used to start
    application 5000 ENV variable is set)
  * `ELASTICSEARCH_URL` - elasticsearch url
  * `STORAGE_DIR` - active storage local dir (default set to
    `RAILS_ROOT/storage`)
  * `S3_STORAGE` - set true to change ActiveStorage to S3
  * `S3_BUCKET` - active storage S3 bucket
  * `S3_ENDPOINT` - active storage S3 endpoint
  * `SMTP_ADDRESS` - smtp mail server address
  * `SMTP_USERNAME` - smtp user name or email address
  * `SMTP_PASSWORD` - smtp password
  * `FROM_EMAIL` - from email (if not set `from@example.com` will be used)
  * `GOOGLE_ANALYTICS` - google analytics key for GMT (if present than analytics
    script is added into head section)
  * `PORTAL_BASE_URL` - portal base URL used to generate footer and other static
    links to EOSC portal
  * `PROVIDERS_DASHBOARD_URL` - Provider's Dashboard URL used to create links to the provider's dashboard
  * `ASSET_HOST` and `ASSET_PROTOCOL` - assets mailer config is mandatory
    (e.g. ASSET_HOST = marketplace.eosc-portal.eu/ and ASSET_PROTOCOL = https )
  * `RATE_AFTER_PERIOD` - number of days after which user can rate resource (default is set to 90 days)
  * `ATTRIBUTES_DOCS_URL` - offer attributes definition documentation (external link)
  * `AUTOLOGIN_DOMAIN` - parent domain in which the autologin scheme should work (see [autologin](#autologin-across-eosc-portaleu-domains))
  * ENV Variables connected to JIRA integration are described in [JIRA integration manual](./docs/jira_integration.md)

## Commits

Running `./bin/setup` automatically installs githooks (using `overcommit` gem) for code linting. But if you're using
an IDE for repository management then you will probably experience problems with commiting
code changes. This is related to the fact that some IDE's do not inherit user's `.bash_profile`
or any other scripts which traditionally set OS environmental variables.

Installed githooks require access to ruby, so ruby environment must be available for IDE.

If you are using asdf-based ruby installation and IDE like RubyMine, the solution is placing asdf 
sourcing commands at the end of your `.profile` file which is inherited by graphical applications 
(unlike `.bashrc` that is standard place for asdf sourcing commands):

```
. $HOME/.asdf/asdf.sh
. $HOME/.asdf/completions/asdf.bash
```

Other solutions could be:
  * For OSX: calling `sudo launchctl config user path $PATH`
  * For Linux systems: modifying `PATH` in `/etc/environment`.
  
**Remember** that before pushing to git, `overcommit` runs rspec tests and it needs running 
[Elasticsearch server](#elasticsearch) in the background. 

You can also skip githooks altogether using:
```
 git <command> --no-verify
```
... or by unchecking 'run Git hooks' in RubyMine IDE when applying git operations.

## Designing UI without dedicated controller

If there is no view yet implemented than still designing team can play around
and create `haml`, `scss`, `js` for this view. For this purpose `designsystem`
section is created. It is available **ONLY** in development mode. The URL is
`/designsystem/:file`, where `:file` is the name of the view created in
`app/views/designsystem` directory. For example `/designsystem/profile` URL will
render `app/views/designsystem/profile.html.haml` file.

Since this is only for development there is no security and template
existence checks.

## Database

To setup development and test databases, you need to have a proper postgres role defined:
```
<your_system_username>:~$ sudo -u postgres -i
postgres:~$ psql
postgres=# CREATE ROLE <your_system_username> PASSWORD <your_system_password> SUPERUSER CREATEDB LOGIN;
```

By default we are using pure rails database configuration in development and
test environments (sockets and database login the same as your system login).
If this is not enough you can customize it by using environment variables:
  * `MP_DATABASE_HOST` - PostgreSQL database host
  * `MP_DATABASE_USERNAME` - PostgreSQL database username
  * `MP_DATABASE_PASSWORD` - PostgreSQL database password


## OpenAPI docs
Marketplace is using OpenAPI documentation standard([swagger](https://swagger.io/)). To do this we are using `rswag` gem.
To check API documentation go to `/api-docs`.

The docs are generated from specs (`/spec/requests/api/{api_version}`). 
There is a special DSL (https://github.com/rswag/rswag) for writing specs in OpenAPI fashion. 

When you write/change api specs run:
```
./bin/rails rswag
```
...to generate and deploy new swagger docs (no server restart required).

You can also customize OpenAPI metadata (such as default port, authentication scheme etc.) in `spec/swagger_helper.rb`

## Views, locales and scss customization

Views, JS and SCSS can be customized by adding `CUSTOMIZATION_PATH` [env variable](#environmental-variables).
This variable should point to the directory with the following structure:

```
/my/customization/dir
  - views
  - javascript
  - config/locales
```

**Warning**: when new SCSS / image / asset is added to customization directory rails application
needs to be restarted.

## Recommender app integration

Marketplace is connected to an [external app](https://github.com/cyfronet-fid/recommender-system) 
which recommends services to users. 

It needs the MP data to learn. The recommended way to update recommender is via `/update` task:
```
./bin/rails recommender:update
```
It sends DB dump to recommender, starts training and reload agent.

If you want only sent a DB dump, use:
```
./bin/rails recommender:serialize_db
```
...to send the database dump to the recommender system.

If you want to save database dump to a json file, use:

```
./bin/rails recommender:serialize_db_to_file
```

## Rake tasks

### Adding Provider OMS

Task: `ordering_api:add_provider_oms`.

Arguments (envvars):
- `ARG_OMS_NAME`, for example `organization_x`, then the OMS will be called `Organization X OMS`
- `ARG_PROVIDER_PID`, the provider must exist for the task to succeed
- `ARG_AUTHENTICATION_TOKEN`, optional, the task will update the OMS admin's token to this value

The task will look create an OMS with `type=:provider_group` that is associated with passed provider.
It will also create an admin user for the OMS, setting its token if passed as argument.

If OMS already exists, then the task will append the provider to the OMS.

Example run:
```
rake ordering_api:add_provider_oms \
  ARG_OMS_NAME="extra_provider" \
  ARG_PROVIDER_PID="ep" \
  ARG_AUTHENTICATION_TOKEN="a_token"
```

## Active Storage

Default ActiveStorage is set to :local with `STORAGE_DIR` env variable (default set to `RAILS_ROOT/storage`).
You can change it in `production` and `development` to S3-compatible resource by setting `S3_STORAGE` 
[env variable](#environmental-variables).

To use S3 first, you need:
* `S3_STORAGE`
* `S3_ENDPOINT`
* `S3_BUCKET`
* s3:access_key_id credentials
* s3:secret_access_key credentials
  
Store s3 access and secret_access keys in encrypted credentials.
Set env variables and you should be able to run the app.
  
### Upload Local ActiveStorage to S3

To upload files registered in db from `local` to `S3` you need:
* working db with registered `local` files
* `S3_ENDPOINT`
* `S3_BUCKET`
* s3:access_key_id credentials
* s3:secret_access_key credentials

Task: `rake storage:upload_to_s3`

### Upload S3 ActiveStorage to S3

To upload files registered in db from `S3` to `local` you need:
* working db with registered `local` files
* `S3_ENDPOINT`
* `S3_BUCKET`
* s3:access_key_id credentials
* s3:secret_access_key credentials

Task: `rake storage:upload_to_local`

### Autologin across `.eosc-portal.eu` domains

We are using a simple scheme to implemented autologin across `.eosc-portal.eu` domains.
It's done via cookies - the user is redirected to `/user/auth/checkin` through JS function call if certain conditions are met (see below)
(this should eventually be done in [EOSC Commons](https://github.com/cyfronet-fid/eosc-portal-common) component).

2 cookies are being set or deleted respectively to the Portal component or the Portal AAI session state:
- `eosc_logged_in` (value: `true`, domain: `.eosc.portal.eu`, expires: `<SAME AS AAI SESSION>`)
- `internal_session` (value: `true`, expires: `<SAME AS INTERNAL SESSION>`) 

Basically the user is redirected `if eosc_logged_in && !internal_session`.

After the logout, both of the cookies are set to `false`.

For more info, click [here](https://docs.cyfronet.pl/pages/viewpage.action?spaceKey=FID&title=.eosc-portal.eu+domain+level+auto-login+%28SSO%29+research)