# README

![Build Status](https://github.com/cyfronet-fid/marketplace/actions/workflows/ci.yml/badge.svg?branch=master)
![Build Status](https://github.com/cyfronet-fid/marketplace/actions/workflows/e2e.yml/badge.svg?branch=master)

Marketplace is a place where you can find resources you need for your research:

- free of charge resources for researchers
- unified order management
- compatible resources linking to ready to use environments

## Development environment

### Requirements

We will need:

- ruby (specific version can be found in [.tool-versions](.tool-versions)).
  Recommended way to manage ruby versions is to use [asdf](https://github.com/asdf-vm/asdf)
  with [asdf-ruby](https://github.com/asdf-vm/asdf-ruby) plugin
- nodejs (specific version can be found in [.tool-versions](.tool-versions)).
  Recommended way to manage nodejs versions is to use [asdf](https://github.com/asdf-vm/asdf)
  with [asdf-nodejs](https://github.com/asdf-vm/asdf-nodejs) plugin.
- yarn (specific version can be found in [.tool-versions](.tool-versions)).
  Recommended way to manage yarn versions is to use [asdf](https://github.com/asdf-vm/asdf)
  with [asdf-yarn](https://github.com/twuni/asdf-yarn) plugin.
- [imagemagick](https://imagemagick.org/script/install-source.php).
  After installation use `convert --version`
  to verify your delegates. If `png` is missing please refer to the
  [related issue](https://askubuntu.com/questions/745660/imagemagick-png-delegate-install-problems).
- [vips](https://github.com/libvips/libvips) The second, alternative
  images processor included in rails 7 and ImageProcessing gem
- [docker compose 1](https://docs.docker.com/compose/)
  (Compose 2 is still in the making)

If you are using [asdf](https://github.com/asdf-vm/asdf) the easiest way to
install required ruby and nodejs versions is to type

```shell
asdf install
```

in marketplace root directory. Ruby and nodejs versions will be set in automatic
way.

### Setup

Before running `./bin/setup` you need to:

- create file `config/master.key` with appropriate content
  in order to make `config/credentials.yml.enc` decryptable.
- run docker services (i.e. postgresql, redis and elasticsearch) (see [docker compose](#docker-compose)).

To set up the environment run `./bin/setup`. It will install bundler, foreman,
dependencies and setup databases (development and test).

### Generating DB entries for development

Filling the database is done by parsing yaml: `db/data.yml`.
Data comes from the actual official version of the marketplace.
If you want to update the data or add new resources/categories,
you can add new records by editing `db/data.yml`.
It is important to remember that if some record
is a parent for another, it must be written above its child.

```shell
./bin/rails dev:prime
```

If you need actual production data run:

```shell
./bin/rake import:vocabularies
./bin/rake import:catalogues
./bin/rake import:providers
./bin/rake import:resources
./bin/rake import:datasources
./bin/rake import:guidelines
```

to seed the database with it.
You can download only specific providers/resources
by setting an `IDS` environment variable.
You can omit images downloading by set variable `MP_IMPORT_RESCUE_MODE` to `true`

## Run

To start web application in development mode (with auto refresh capability when
css/js files change) use following command:

```shell
./bin/server
```

It uses foreman and start processes defined in `Procfile.dev`.
Script also checks if [overmind](https://github.com/DarthSim/overmind)
is present in the classpath and uses it instead of `foreman`.
`overmind` is more advanced than `foreman` and plays nicely with e.g. `byebug`.

> Currently there is a problem with stopping overmind process when sidekiq is
> used in versions
> [2.1.1 and 2.1.0](https://github.com/DarthSim/overmind/issues/76) -
> use `2.0.3` instead.

By default application should start on [http://localhost:5000](). You can change
port by setting [env variable](#environmental-variables) `PORT`.
You also need to run postgresql,
Elasticsearch and Redis in the [background](#docker-compose) before starting the
application server.

## Docker compose

Docker compose is used to manage
background services: postgresql, Elasticsearch and Redis.
The service containers are named `db`, `el` and `redis`, accordingly.
Inspect the `docker-compose.yml` file for their configuration.

- postgresql is used to store data,
- Elasticsearch is used for full text resource search,
- Redis is used to pass state to sidekiq (for running background jobs).

To run all the services at once `$ docker compose up -d` (remove `-d` to run in foreground).
You can later inspect logs `$ docker compose logs`.
Lastly, to remove the containers (with data)
`$ docker compose down -v` (remove `-v` not to remove DB data).

To run specific service `<serv>` in foreground `$ docker compose up <serv>`.
To stop it `$ docker compose stop <serv>`,
and to remove its state: `$ docker compose rm <serv>`

## FriendlyId

Marketplace uses FriendlyId slugs made from a name of resource.
In case of deleted resources, which block friendly-looking slug,
if we want to have a published copy, its slug looks like this:
`some-slug-51daddab-9a34-406e-b1c4-87acea5572cb`
To unlock and assign friendly slugs for published resources run task:
`rake friendly_id:heal`

## JIRA

Marketplace is integrating with jira on a rather tight level.
For tests JIRA is mocked, and for normal
development connection from MP to JIRA is provided.
All fields and JIRA variables are stored
in encrypted credentials. The default project to which
issues are written is `EOSCSODEV`.
If you require backward communication from JIRA to your application
you can use reverse tunnel to connect WH
to your local application instance. To do so execute following command
(first make sure that your local instance of marketplace has been started already):

```shell
ssh -R <port_number - from 9001 to 9015>:
localhost:5000 mszostak@docker-fid.grid.cyf-kr.edu.pl -N
```

If you can not connect, try different port -
it is possible that other developer connected
to this port and is blocking it.

## XGUS

Marketplace is integrated with xGUS Helpdesk.
All variables needed to establish a connection
to the test instance are stored in encrypted credentials.
To run integration test there is a need to type `rake xgus:check` in the console.
To run on different than test instance, there is a need do set [env variables](#environmental-variables):

- `MP_XGUS_USERNAME`
- `MP_XGUS_PASSWORD`
- `MP_XGUS_WSDL`

## Google Analytics API

Marketplace has integration with Google Analytics
and shows users with executive roles resources unique visits counter.
Default period is 1 month,

## ReCaptcha

ReCaptcha is now used in the ask resource question form.
To work it needs to set 2 [env variables](#environmental-variables):
`RECAPTCHA_SITE_KEY` and `RECAPTCHA_SECRET_KEY`.
For test, development and internal docker instances
values of these variables are stored in encrypted credentials.

## For Admins

If you are an admin, who wants to integrate production instance of JIRA go to
[JIRA integration manual](./docs/jira_integration.md) otherwise read on.

Additionally there is HD / Feedback mechanism implemented using JIRA collectors.
In order to enable it in production following environmental variable should be set:

- `JIRA_COLLECTOR_SCRIPTS`

This variable should be set to the address of script
(or scripts - space separated) which are generated when
configuring JIRA collector in JIRA instance.
Sample declaration of this variable can be as follows (for two scripts)

Note the space separating both scripts sources

```shell
JIRA_COLLECTOR_SCRIPTS="https://jira.example.com/s/xxx-CDN/xx/00/xxx/x.x.x.x/_/download/batch/
com.atlassian.plugins.jquery:jquery/com.atlassian.plugins.jquery:jquery.js?collectorId=00000
https://jira.example.com/s/xxx/xxx/0/xxx/x.x.x/_/download/batch/
com.atlassian.jira.collector.plugin.jira-issue-collector-plugin:issuecollector/
com.atlassian.jira.collector.plugin.jira-issue-collector-plugin:issuecollector.js?locale=en-UK&collectorId=yyyyy"
```

## Sentry integration

In production environment sentry integration can be turned on. To do so create
dedicated [env variable](#environmental-variables)
`SENTRY_DSN` with details how to connect to sentry server.
Sentry environment can also be configured using `SENTRY_ENVIRONMENT`
[env variable](#environmental-variables) (default set to `production`).

## Environmental variables

This project can be customized via numerous environmental variables.
To make storing them a little easier `dotenv` gem has been employed.
You can read documentation [here](https://github.com/bkeepers/dotenv).

You can store your env variables in `.env` file in the root of the project.
You can then access them in ruby code via:

```ruby
ENV[VAR]
```

We are currently using the following ENV variables:

- `MP_VERSION` (Optional) - the application's version
  (default taken from the file `./VERSION`)
- `PORT` (Optional) - http server port (default 5000)
- `CHECKIN_HOST` (Optional) - checkin IDP host (default `aai-dev.egi.eu`)
- `CHECKIN_SCOPE` (Optional) - checkin IDP scope
  (default `["openid", "profile", "email", "refeds_edu"]`)
  multiple scopes separated by `,`, e.g `CHECKIN_SCOPE=openid,email`
- `CHECKIN_IDENTIFIER` (Optional) - checkin IDP identifier (default taken from
  encrypted properties)
- `CHECKIN_SECRET` (Optional) - checkin IDP secret (default taken from
  encrypted properties)
- `OIDC_AAI_NEW_API` - if you want to use old AAI endpoints, set it to false
- `ROOT_URL` (Optional) - root application URL (default
  `http://localhost:#{ENV["PORT"] || 3000}` (when foreman is used to start
  application 5000 ENV variable is set)
- `ELASTICSEARCH_URL` - elasticsearch url
- `RECOMMENDER_HOST` - address of the recommender system. For example: `http://127.0.0.1:5001`
- `RECOMMENDATION_ENGINE` - the name of the engine that
  is requested to serve recommendations when a request
  from MP is sent to the RS `/recommendations` endpoint.
  We currently support RL and NCF.
- `STORAGE_DIR` - active storage local dir (default set to
  `RAILS_ROOT/storage`)
- `S3_STORAGE` - set true to change ActiveStorage to S3
- `S3_BUCKET` - active storage S3 bucket
- `S3_ENDPOINT` - active storage S3 endpoint
- `S3_ACCESS_KEY_ID` - active storage S3 access key
- `S3_SECRET_ACCESS_KEY` - active storage S3 secret access key
- `SMTP_ADDRESS` - smtp mail server address
- `SMTP_USERNAME` - smtp user name or email address
- `SMTP_PASSWORD` - smtp password
- `FROM_EMAIL` - from email (if not set `from@example.com` will be used)
- `GOOGLE_ANALYTICS` - google analytics key for GMT (if present than analytics
  script is added into head section)
- `PORTAL_BASE_URL` - portal base URL used to generate footer and other static
  links to EOSC portal
- `PROVIDERS_DASHBOARD_URL` - Provider's Dashboard URL
  used to create links to the provider's dashboard
- `USER_DASHBOARD_URL` User Dashboard URL for links
  in the landing page. Default is `https://my.eosc-portal.eu/`
- `ASSET_HOST` and `ASSET_PROTOCOL` - assets mailer config is mandatory
  (e.g. ASSET_HOST = marketplace.eosc-portal.eu/ and ASSET_PROTOCOL = https )
- `RATE_AFTER_PERIOD` - number of days after which user
  can rate resource (default is set to 90 days)
- `ATTRIBUTES_DOCS_URL` - offer attributes definition documentation (external link)
- `AUTOLOGIN_DOMAIN` - parent domain in which the autologin
  scheme should work (see [autologin](#autologin-across-eosc-portaleu-domains))
- `EOSC_COMMONS_ENV` - EOSC commons environment type enum: 'production'/'development'
- `EOSC_COMMONS_BASE_URL` \- EOSC commons base URL: s3 instance + bucket
- ENV Variables connected to JIRA integration
  are described in [JIRA integration manual](./docs/jira_integration.md)
- `MP_STOMP_CLIENT_NAME` (Optional) - stomp client name (default `MPClient`)
- `MP_STOMP_LOGIN` (Optional) - stomp client login (default from `credentials.stomp.login`)
- `MP_STOMP_PASS` (Optional) - stomp client password (default from `credentials.stomp.password`)
- `MP_STOMP_HOST` (Optional) - stomp client host (default from `credentials.stomp.host`)
- `MP_STOMP_DESTINATION` (Optional) - stomp client destination (default from `credentials.stomp.subscriber.destination`)
- `MP_STOMP_SSL` (Optional) - stomp connection SSL (default `false`)
- `MP_STOMP_PUBLISHER_ENABLED` (Optional) -
  turn on publishing with JMS if set to `true` (default `false`)
- `MP_STOMP_PUBLISHER_LOGGER_PATH` (Optional) -
  path to the JMS log file (default `"RAILS_ROOT/log/jms.publisher.log"`)
- `MP_STOMP_PUBLISHER_TOPIC` (Optional) -
  topic of a new message to be published (default `credentials.stomp.publisher.topic`)
- `MP_STOMP_PUBLISHER_MP_DB_EVENTS_TOPIC` (Optional) -
  topic for publishing database create, update and destroy events (default `mp_db_events`)
- `MP_STOMP_PUBLISHER_USER_ACTIONS_TOPIC` (Optional) -
  topic for publishing user actions events(default `user_actions`)
- `MP_ENABLE_EXTERNAL_SEARCH` - should be set to `1`
  if external search is used. If set top bars will be replaced
- `SEARCH_SERVICE_BASE_URL` - default: `https://search.marketplace.eosc-portal.eu`
- `USER_ACTIONS_TARGET` (Optional) - target to which user_actions
  should be published (options: `all, recommender, databus`) (default `all`)
      - For the `databus` target to work you must also
        enable JMS publishing, i.e. set `MP_STOMP_PUBLISHER_ENABLED=true`.
- `ESS_UPDATE_ENABLED` (Optional) - turn on updating ESS
  if set to `true` (default `false`)
- `ESS_UPDATE_URL` (Optional) - URL to which service
  updates will be sent (default `http://localhost:8983/solr/marketplace/update`)
- `ESS_UPDATE_TIMEOUT` (Optional) - ESS update HTTP
  client timeout in seconds (default `1`)
- `ESS_RESOURCE_CACHE_TTL` (Optional) - TTL for caching resources
  for `ess/` API endpoints (default `60` (seconds))
- **Provider importer**
      - `IMPORTER_AAI_BASE_URL` (Optional) - Base URL used to generate
        access token from a refresh token (default `ENV["CHECKIN_HOST"]` or "aai.eosc-portal.eu")
      - `IMPORTER_AAI_REFRESH_TOKEN` - The refresh token
        generated for specific instance of AAI
      - `IMPORTER_AAI_CLIENT_ID` (Optional) - The client id for the generated
        refresh token (default `ENV["CHECKIN_IDENTIFIER"]`
        or `Rails.application.credentials.checkin[:identifier]`)
- `SHOW_RECOMMENDATION_PANEL` - Boolean (true/false) indicating
  if recommendation panel should be visible or not. Defaults to true

## Commits

Running `./bin/setup` automatically installs githooks
(using `overcommit` gem) for code linting. But if you're using
an IDE for repository management then
you will probably experience problems with committing code changes.
This is related to the fact that some IDE's do not inherit user's `.bash_profile`
or any other scripts which traditionally set OS environmental variables.

Installed githooks require access to ruby,
so ruby environment must be available for IDE.

If you are using asdf-based ruby installation and IDE like RubyMine,
the solution is placing asdf
sourcing commands at the end of your `.profile`
file which is inherited by graphical applications
(unlike `.bashrc` that is standard place for asdf sourcing commands):

```shell
. $HOME/.asdf/asdf.sh
. $HOME/.asdf/completions/asdf.bash
```

Other solutions could be:

- For OSX: calling `sudo launchctl config user path $PATH`
- For Linux systems: modifying `PATH` in `/etc/environment`.

You can also skip githooks altogether using:

```shell
 git <command> --no-verify
```

... or by unchecking 'run Git hooks' in RubyMine IDE
when applying git operations, or setting `OVERCOMMIT_DISABLE=1`
envvar globally in your system.

### Linting and code formatting

We use prettier for code formatting and a specifically configured
Rubocop, inspect `.prettierrc`, `.prettierignore`
and `rubocop.yml` for specifics.

To correct formatting with prettier `$ rbprettier --write .`
(it will take some time), you may want to run it
selectively on modified files only
(just pass them as explicit arguments instead of a dot `.`).

To manually run all overcommit checks `$ overcommit --run`
(you may need to sign configs, first, just follow its instructions).
It's configured in `.overcommit.yml`.

To run rubocop manually `$ rubocop`.

To run haml-lint manually `$ haml-lint --exclude 'lib/**/*.haml'`.

To run brakeman (it's only run directly in CI though,
not through overcommit) manually (in interactive mode)
`$ brakeman -I`.

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

In general, [docker compose](#docker-compose) correctly manages DB permissions.
Nevertheless, if using a direct postgresql install
or you want to use socket communication, than the below info may
be useful.

To setup development and test databases,
you need to have a proper postgres role defined:

```shell
<your_system_username>:~$ sudo -u postgres -i
postgres:~$ psql
postgres=# CREATE ROLE <your_system_username>
  PASSWORD <your_system_password> SUPERUSER CREATEDB LOGIN;
```

You may configure the application to use
pure rails database configuration in development and
test environments (sockets and database login the same as your system login).
You can customize it by using environment variables:

- `MP_DATABASE_HOST` - PostgreSQL database host
- `MP_DATABASE_USERNAME` - PostgreSQL database username
- `MP_DATABASE_PASSWORD` - PostgreSQL database password

## Tag healing

There's created task for healing case of tags.
Fill `HEAL_TAG_LIST` environment variable like below:

`HEAL_TAG_LIST="EOSC::Jupyter Notebook,EOSC::Galaxy Workflow,EOSC::Twitter Data"`

and run `rake viewable:heal_tags` to change case of letters to input.
If you don't fill this variable, the task runs
on the default discovered defective tags.

## SOLR dumps

You can use a rake task `ess:dump[#{collections}]` to get data in
`#{collection}.json` prepared for SOLR-Transformation API/script.
Possible options:

- all
- providers
- services
- datasources
- offers
- bundles

E.g. call `rake ess:dump[all]` to return all collections,
`rake ess:dump[providers]` will generate file providers.json,
and `rake ess:dump[services offers]` creates services.json and offers.json

## SOLR Live connection

Set ENV variable `ESS_UPDATE_ENABLED` to `true`
to enable live update objects to the SOLR transformation service.
To get it working set also `ESS_UPDATE_URL`.

## Data To SOLR REST API

There are endpoints for getting data to SOLR transformation service.
Data is accessible via the path:
`api/v1/ess/{{ collection }}`
where the collection can be:

- services
- datasources
- providers
- offers
- bundles

There is a possibility to get object by id,
and in case of service/datasource/provider by slug or pid
just by add `/{{ id }}` to path,
eg. `/api/v1/ess/services/egi-cloud-compute`

You can test endpoints in the mp swagger

NOTICE!
To get the data you have to login
or authenticate via the user's access_token
with `service_portfolio_manager` role

## Statistics update rake task

Usage statistics are now stored in the db,
and update everytime someone visit service/provider/bundle page.
For get current state for all collections (necessary for ESS dump)
run

```shell
rake viewable:cache_views_count
```

All data is logged in the `log/cache_views_count.log`

## OpenAPI docs

Marketplace is using OpenAPI documentation
standard([swagger](https://swagger.io/)). To do this we are using `rswag` gem.
To check API documentation go to `/api-docs`.

The docs are generated from specs (`/spec/requests/api/{api_version}`).
There is a special DSL <https://github.com/rswag/rswag>
for writing specs in OpenAPI fashion.

When you write/change api specs run:

```shell
./bin/rails rswag
```

...to generate and deploy new swagger docs (no server restart required).

You can also customize OpenAPI metadata (such as default port,
authentication scheme etc.) in `spec/swagger_helper.rb`

## Views, locales and scss customization

Views, JS and SCSS can be customized by adding `CUSTOMIZATION_PATH` [env variable](#environmental-variables).
This variable should point to the directory with the following structure:

```shell
/my/customization/dir
  - views
  - javascript
  - config/locales
```

**Warning**: when new SCSS / image / asset is added
to customization directory rails application
needs to be restarted.

## OG meta_tags

There are set default OG tags but you can use
following environmental variables to customize them:

- `MP_META_TITLE` - for custom `og:title`
- `MP_META_DESCRIPTION`- for custom `og:description`

## Recommender app integration

Marketplace is connected to an
[external app](https://github.com/cyfronet-fid/recommender-system)
which recommends services to users.

It needs the MP data to learn. The recommended way
to update recommender is via `/update` task:

```shell
./bin/rails recommender:update
```

It sends DB dump to recommender, starts training and reload agent.

If you want only sent a DB dump, use:

```shell
./bin/rails recommender:serialize_db
```

...to send the database dump to the recommender system.

If you want to save database dump to a json file, use:

```shell
./bin/rails recommender:serialize_db_to_file
```

## Rake tasks

### Adding Provider OMS

Task: `ordering_api:add_provider_oms`.

Arguments (envvars):

- `ARG_OMS_NAME`, for example `organization_x`,
  then the OMS will be called `Organization X OMS`
- `ARG_PROVIDER_PID`, the provider must exist for the task to succeed
- `ARG_AUTHENTICATION_TOKEN`, optional,
  the task will update the OMS admin's token to this value

The task will look create an OMS with `type=:provider_group`
that is associated with passed provider.
It will also create an admin user for the OMS,
setting its token if passed as argument.

If OMS already exists, then the task will append the provider to the OMS.

Example run:

```shell
rake ordering_api:add_provider_oms \
  ARG_OMS_NAME="extra_provider" \
  ARG_PROVIDER_PID="ep" \
  ARG_AUTHENTICATION_TOKEN="a_token"
```

### ESS updating

Task: `ess:reindex:all`.

The task clears the ESS core/collection and reindexes all the eligible services.

The operation runs synchronously, bypassing Sidekiq.

## Active Storage

Default ActiveStorage is set to :local with `STORAGE_DIR`
env variable (default set to `RAILS_ROOT/storage`).
You can change it in `production` and `development`
to S3-compatible resource by setting `S3_STORAGE`
[env variable](#environmental-variables).

To use S3 first, you need:

- `S3_STORAGE`
- `S3_ENDPOINT`
- `S3_BUCKET`
- s3:access_key_id credentials or in `S3_ACCESS_KEY_ID`
- s3:secret_access_key credentials or in `S3_SECRET_ACCESS_KEY`

Store s3 access and secret_access keys in encrypted credentials.
Set env variables and you should be able to run the app.

### Upload Local ActiveStorage to S3

To upload files registered in db from `local` to `S3` you need:

- working db with registered `local` files
- `S3_ENDPOINT`
- `S3_BUCKET`
- s3:access_key_id credentials or in `S3_ACCESS_KEY_ID`
- s3:secret_access_key credentials or in `S3_SECRET_ACCESS_KEY`

Task: `rake storage:upload_to_s3`

### Upload S3 ActiveStorage to S3

To upload files registered in db from `S3` to `local` you need:

- working db with registered `local` files
- `S3_ENDPOINT`
- `S3_BUCKET`
- s3:access_key_id credentials or in `S3_ACCESS_KEY_ID`
- s3:secret_access_key credentials or in `S3_SECRET_ACCESS_KEY`

Task: `rake storage:upload_to_local`

### Autologin across `.eosc-portal.eu` domains

We are using a simple scheme to implemented autologin across `.eosc-portal.eu` domains.
It's done via cookies - the user is redirected to `/user/auth/checkin`
through JS function call if certain conditions are met (see below)
(this should eventually be done
in [EOSC Commons](https://github.com/cyfronet-fid/eosc-portal-common) component).

2 cookies are being set or deleted respectively
to the Portal component or the Portal AAI session state:

- `eosc_logged_in` (value: `true`, domain: `.eosc.portal.eu`,
  expires: `<SAME AS AAI SESSION>`)
- `internal_session` (value: `true`, expires: `<SAME AS INTERNAL SESSION>`)

Basically the user is redirected `if eosc_logged_in && !internal_session`.

After the logout, both of the cookies are set to `false`.

For more info, click [here](https://docs.cyfronet.pl/pages/viewpage.action?spaceKey=FID&title=.eosc-portal.eu+domain+level+auto-login+%28SSO%29+research)

## ESS update, local integration

Start a local Solr instance by executing:

```shell
cd solr; docker compose up
```

It will set up a local instance with a single core `marketplace`.
The web interface should be accessible under <http://localhost:8983/solr/>
with the core available under "Core selector".
The core should be empty at this point.

Run a local instance of MP with `ESS_UPDATE_ENABLED=true` and seed it with data.
During the seeding the core should be populated,
to verify it's the case go to the "Query" section and execute
a query, or just run it directly with `GET <http://localhost:8983/solr/marketplace/select?q=*%3A*>`.

In case you didn't seed the DB and still want to propagate data
then run `rails ess:reindex:all` to reindex the service collection.
The effect should be analogous.

To verify updating the ESS entries, run the following
in the rails console and observe `q=id:16` Solr queries:

```ruby
Service.find(16).update!(status: :draft) # the entry should be removed
Service.find(16).update!(status: :published) # the entry should reappear
Service.find(16).update!(tagline: "foo bar") # the entry's tagline should update
```
