# Staging deploy

Two scripts in this directory deploy the staging environment on one host:

- `deploy-multi.sh` deploys the marketplace instances of the three variants:
  marketplace, pl and whitelabel.
- `deploy-hubs.sh` deploys the discovery hubs of pl and marketplace, each with
  its own Solr, transform service and EOSC commons.

Run the scripts by hand on the host. The goal is a GitHub Actions workflow
that runs the scripts after a push to the deploy branch. The workflow does not
exist yet. The section "GitHub Actions" describes the plan and the open
point.

## What runs on the host

| Variant     | Instance project            | Instance              | Port | Hub project                     | Hub              | Port |
|-------------|-----------------------------|-----------------------|------|---------------------------------|------------------|------|
| marketplace | mp-multitenancy-marketplace | marketplace-18.DOMAIN | 3018 | mp-multitenancy-marketplace-hub | search-18.DOMAIN | 3218 |
| pl          | mp-multitenancy-pl          | marketplace-16.DOMAIN | 3016 | mp-multitenancy-pl-hub          | search-16.DOMAIN | 3216 |
| whitelabel  | mp-multitenancy-whitelabel  | marketplace-17.DOMAIN | 3017 | none                            | none             | none |

`staging-urls.sh` holds DOMAIN and the slot of each variant. The Apache
reverse proxy of the host ends TLS and forwards each vhost to the port of the
table. Each project has its own network and its own volumes.

Services of an instance project, `docker-compose-<variant>.yml`:

- `web`: the Rails application, one image per variant. The repository
  `Dockerfile` gets the variant and the path of its frontend as build
  arguments.
- `worker`: Sidekiq, the same image.
- `db`: Postgres 16, named volume.
- `el`: Elasticsearch 7.5.
- `redis`.

Services of a hub project, `docker-compose-hub-<variant>.yml`:

- `api`: the backend of the hub. The container runs the alembic migrations,
  then uvicorn.
- `ui`: the Angular build of the hub behind nginx, image from
  `hub/ui.Dockerfile`. The nginx of `hub/nginx.conf` proxies `/api/` to `api`
  and `/commons/` to `commons`.
- `commons`: the EOSC commons bundle with the header and the footer, image from
  `hub/commons.Dockerfile`.
- `db`: Postgres 14 of the hub.
- `zoo` and `solr`: Solr 8.11 in cloud mode. The configsets of the hub
  checkout are mounted by name. Named volumes.
- `redis`: the broker of the transform service.
- `transform-api` and `transform-worker`: the transform service, one image. The
  worker reads the marketplace API of the variant and writes to Solr.

## Files on the host

ROOT is the parent directory of the checkout. The scripts derive ROOT from
their own location. `MP_SEED_DIR` and `MP_HUBS_DIR` point to other seed and
hubs directories.

```
ROOT/marketplace                          this repository, a deploy artifact
ROOT/marketplace/marketplace-<variant>.env settings and secrets of an instance
ROOT/seed/<variant>/mp_db.sql             database dump, first deploy only
ROOT/seed/<variant>/media/                media files, first deploy only
ROOT/.last-deployed-commit                commit of the last complete run
ROOT/hubs/<variant>                       checkout of the hub
ROOT/hubs/transform-service               checkout of the transform service
ROOT/hubs/eosc-pl-common                  commons checkout of the pl hub
ROOT/hubs/eosc-portal-common              commons checkout of the marketplace hub
ROOT/hubs/<variant>.env                   settings and secrets of a hub
ROOT/hubs/.last-deployed-<variant>        state of the last complete hub deploy
```

## Setup before the first deploy

1. Clone this repository to `ROOT/marketplace` and check out the deploy
   branch. The scripts reset the checkout to the upstream branch at each run.
2. Write `marketplace-<variant>.env` in the checkout for each variant.
   `.env.example` lists the variables. The pl and marketplace compose files set
   `ROOT_URL`, `SEARCH_SERVICE_BASE_URL`, `EOSC_COMMONS_BASE_URL` and
   `EOSC_COMMONS_ENV` from the staging URLs. The compose values have precedence
   over the env file.
3. Put a database dump at `ROOT/seed/<variant>/mp_db.sql` and the media files
   in `ROOT/seed/<variant>/media/`.
4. Create `ROOT/hubs` with write permission for the user who runs the script.
5. Write `ROOT/hubs/<variant>.env` for pl and marketplace. The header of the
   hub compose file lists the variables: `MP_API_TOKEN` of a coordinator of
   the instance, `SECRET_KEY`, `OIDC_CLIENT_ID`, `OIDC_CLIENT_SECRET` and
   `LOG_LEVEL`. The OIDC client is a client of the Keycloak `core` of the host with
   the redirect URI `<hub URL>/api/web/auth/checkin`.

## Run

Run the scripts of the checkout from ROOT. Deploy the instance before its hub:
`deploy-hubs.sh` does not update the marketplace checkout, and the transform
service reads the marketplace API of the instance.

```sh
cd <ROOT>
./marketplace/lib/versions/deploy-multi.sh pl
./marketplace/lib/versions/deploy-hubs.sh pl
```

| Command                          | Effect                                                                       |
|----------------------------------|------------------------------------------------------------------------------|
| `deploy-multi.sh`                | All variants, only when origin has a new commit.                             |
| `deploy-multi.sh --force`        | All variants, always.                                                        |
| `deploy-multi.sh pl`             | Only pl, always. The state file is not written.                              |
| `deploy-multi.sh --ref <commit>` | All variants at the commit, only when the commit is not the last deployed.   |
| `deploy-multi.sh --no-update pl` | Only pl, without fetch and reset: the checkout as it is, for a local run.    |
| `deploy-multi.sh down pl`        | Remove pl: containers, images, database and media.                           |
| `deploy-hubs.sh`                 | Both hubs, only when a checkout, the hub compose file or `lib/versions/hub` changed. |
| `deploy-hubs.sh pl`              | Only the pl hub, always.                                                     |
| `deploy-hubs.sh seed pl`         | Create the Solr collections of pl if absent, then start a full load.         |
| `deploy-hubs.sh down pl`         | Remove the pl hub: containers, images, database, Solr and Zookeeper volumes. |

The scripts exit with status 0 after a complete run and when there was
nothing to do. A failed variant or hub, a failed `down` or `seed` and a
parallel run exit with status 1.

The scripts do not set the URLs by hand. `staging-urls.sh` exports
`MP_ROOT_URL`, `MP_HUB_URL` and `MP_API_URL` of a variant before each compose
call. A manual `docker compose` call needs the three variables in the shell,
and a hub call also needs `MP_HUBS_DIR` and `MP_APP_DIR`.

## Steps of deploy-multi.sh

1. Take a lock on the checkout. A parallel run exits at once with status 1.
2. Fetch origin and reset the checkout to the upstream branch, or to the
   commit of `--ref`. Local commits and local changes to tracked files are
   lost. Untracked files, for example the env files, stay. `--no-update`
   skips this step.
3. When the reset changed `deploy-multi.sh` or `staging-urls.sh`, start the
   new script with the same arguments. Bash reads the script file while the
   script runs, so the old body stays in effect without the restart. The new
   script finds the checkout at the target and continues with step 4.
4. Without `--force` and without a variant argument, compare HEAD with
   `.last-deployed-commit`. Exit when the two are equal.
5. For each variant:
   1. Export the URLs of the variant from `staging-urls.sh`.
   2. Make sure that the compose file and the dump exist.
   3. Build the image. The old containers still run.
   4. Create the new containers without a start. The named volumes stay.
   5. Start `db` and wait until its healthcheck passes.
   6. Seed when the database has no `schema_migrations` table: copy the media
      into the `web` container, create the database again and restore the dump
      in one transaction.
   7. Start all services. `web` runs the migrations and the Searchkick
      reindex, then Puma.
6. Write HEAD to `.last-deployed-commit` when all variants were deployed.

## Steps of deploy-hubs.sh

1. Take a lock on the hubs directory. A parallel run exits at once with
   status 1.
2. Export `MP_HUBS_DIR` and `MP_APP_DIR` for the compose files.
3. For each hub:
   1. Make sure that the compose file and `hubs/<variant>.env` exist.
   2. Clone or reset three checkouts: the hub, `transform-service` and the
      commons repository. The hub and the transform service deploy their
      `development` branch, the commons its default branch.
   3. Copy the staging environment of the commons from
      `hub/commons/<variant>` into the commons checkout: `env/env.staging.js`
      and the `*.staging.*.json` configuration files.
   4. Compute the state: the three commits, the blob hash of the hub compose
      file and the tree hash of `lib/versions/hub`. The two hashes come from
      HEAD, not from the working tree. Without `--force`, skip the hub when
      the state equals `.last-deployed-<variant>`.
   5. Build the images:
      - `api` from the backend directory of the hub checkout.
      - `ui` from `hub/ui.Dockerfile`. The build argument
        `NG_COLLECTIONS_PREFIX` goes into the Angular build.
      - `commons` from `hub/commons.Dockerfile`. A sed replaces
        `__DISCOVERY_HUB_URL__` with `MP_HUB_URL` and `__MARKETPLACE_URL__`
        with `MP_ROOT_URL`. Then gulp builds `index.staging.min.js` and
        `index.staging.min.css`. The build fails when a placeholder stays.
      - `transform-api` and `transform-worker` from the transform service
        checkout, one image.
   6. Recreate the containers. The volumes of `db`, `solr` and `zoo` stay.
      Solr uploads the configsets to Zookeeper at the first start of its
      volume.
   7. Write the state file.
   8. On the first deploy, seed Solr.

### Seed of Solr

The seed runs after the first deploy and with `deploy-hubs.sh seed <variant>`.
The script reaches Solr and the transform API on the localhost ports of the
compose file: 8916 and 8116 for pl, 8918 and 8118 for marketplace. The
collections prefix is `pl_` for pl and empty for marketplace.

1. Wait until Solr and the transform API answer.
2. When `<prefix>all_collection` does not exist, POST `create_collections` to
   the transform API. The transform worker creates the collections with the
   configsets of its environment. Wait until the collection answers a ping.
3. POST `full?data_type=all` to the transform API. The worker reads all
   resources from `/api/v1/ess` of the instance with `MP_API_TOKEN`,
   transforms them and writes them to Solr. The load runs in the background.

Watch the load with:

```sh
docker logs -f mp-multitenancy-<variant>-hub-transform-worker-1
```

## How the parts connect at runtime

```
browser ──> marketplace-NN (web)  search links ──> search-NN (ui nginx)
               │                                      ├── /          Angular UI
               │ commons header and footer            ├── /api/  ──> api ──> solr, db
               └────────────────────────────────────> └── /commons/ ──> commons
transform-worker ──> marketplace-NN /api/v1/ess ──> solr
```

- The instance builds every search link with `SEARCH_SERVICE_BASE_URL`, which
  the compose file sets to `MP_HUB_URL`. The landing page search, the category
  links and the breadcrumbs go to the hub of the same slot.
- The instance loads the commons header and footer from
  `EOSC_COMMONS_BASE_URL`, which is `MP_HUB_URL/commons/`, with
  `EOSC_COMMONS_ENV=staging`.
- The hub api gives `EOSC_COMMONS_URL` to the hub UI. The UI loads the same
  bundle through its nginx. The bundle links to the hub and to the instance of
  the same slot. Links to services without a staging instance keep their
  production URLs.
- The hub api reads Solr with `COLLECTIONS_PREFIX` and its own database. Users
  of the hub log in through the Keycloak `core` of the host.
- The transform service reads the marketplace API at `MP_API_ADDRESS`, which
  is `MP_API_URL` with the default `MP_ROOT_URL`. The instances do not push
  changes to the hubs: STOMP is off.

## Checks after a deploy

The page source of an instance has a console line
`MP VERSION: mp-multitenancy-<variant> <commit>` and the landing page has
`data-base="<hub URL>"`:

```sh
curl -s <instance URL>/ | grep -o 'MP VERSION[^"]*\|data-base="[^"]*"'
```

The hub answers `<hub URL>/search/all_collection?q=*` with 200, and
`<hub URL>/commons/index.staging.min.js` holds the hub URL. The number of
documents in Solr, on the host:

```sh
curl -s 'http://127.0.0.1:8916/solr/pl_all_collection/select?q=*:*&rows=0'
```

## Error tracking

GlitchTip receives the exceptions of the instances through the Sentry gems.
`docker-compose-glitchtip.yml` runs it on the staging host as the compose
project `glitchtip`: the application in one container, Postgres 18 and
Valkey, the UI on the localhost port 3020. The reverse proxy of the host
serves the slot names only (`marketplace-N.DOMAIN` to the port `30N`), so
GlitchTip takes the slot 20: `https://marketplace-20.DOMAIN`. Production
instances send to the same server.

Setup, once:

1. Write `glitchtip.env` next to the compose file. The header of the compose
   file lists the variables: the secret key, the database password, the
   public URL of the slot, the SMTP URL and the sender address.
2. Start the project. The migrations run at the start.

   ```sh
   cd <ROOT>/marketplace
   docker compose -p glitchtip -f docker-compose-glitchtip.yml up -d
   ```

3. Make sure that the slot answers. The health check needs the public host
   name; a request to `127.0.0.1` gets a 400 from `ALLOWED_HOSTS`.

   ```sh
   curl -sI https://marketplace-20.DOMAIN/_health/
   ```

   Another host sets `MP_GLITCHTIP_PORT` and the two name variables of
   `glitchtip.env` to a free slot of that host.
4. Open the UI and register the first user. Then set
   `ENABLE_USER_REGISTRATION=False` in `glitchtip.env` and run the `up -d`
   command again.
5. Create an organization and one project per variant. The settings of a
   project show its DSN.
6. Add two lines to `marketplace-<variant>.env` of each instance, then deploy
   the variant. A production deployment sets the same two variables with
   `SENTRY_ENVIRONMENT=production`.

   ```
   SENTRY_DSN=<DSN of the project>
   SENTRY_ENVIRONMENT=staging
   ```

`config/initializers/sentry.rb` activates in every environment that sets
`SENTRY_DSN`, so a local run can report to a local GlitchTip too (set
`SENTRY_ENVIRONMENT`, default: the Rails environment). `SENTRY_TRACES_SAMPLE_RATE` (default 0.01) is the share of the
requests stored as transactions. The release of an event is the commit of
`MP_VERSION`, so the UI can filter the events of one deploy. The instance
also sends logs to the Logs view of the project: one entry per request, job
and mail. `SENTRY_LOGS=false` turns the logs off; `SENTRY_LOGS_QUERIES=true`
adds one entry per SQL query, which are many. Test from the web container of
an instance:

```sh
docker exec mp-multitenancy-pl-web-1 bin/rails runner \
  'Sentry.capture_message("test"); Sentry.logger.info("test log"); Sentry.get_current_client.flush'
```

The browser reports to the same project as the server. `SentryHelper`
writes the DSN into meta tags when `SENTRY_DSN` is set, and
`app/javascript/app/sentry.js` starts the Sentry browser SDK from the tags.
The browser reports:

- unhandled JS errors and promise rejections,
- a turbo-frame response without the requested frame (the page shows
  "Content missing"),
- a Turbo fetch request that fails on the network level.

A handled response makes no event. A validation error with status 422
renders the form again and is not an error. The `rescue_from` redirects of
`ApplicationController` (record not found, not authorized) make no server
event. In a turbo-frame request such a redirect shows "Content missing",
and then the browser reports the frame-missing event with the frame id and
the URL.

Upgrade with `docker compose -p glitchtip -f docker-compose-glitchtip.yml pull`,
then the `up -d` command. The data lives in the volumes `glitchtip_pg-data`
and `glitchtip_uploads`. The retention is 90 days (`GLITCHTIP_RETENTION_DAYS`).

## Logs across deploys

A deploy recreates the containers, and Docker removes the log of a removed
container. On the staging host the deploy scripts add
`lib/versions/docker-compose-instance-journald.yml` and
`lib/versions/docker-compose-hub-journald.yml` to the compose calls: the
containers log to the journal of the host, which keeps the logs across
deploys with the retention of journald (`journalctl --disk-usage`,
`SystemMaxUse` in `journald.conf`). `docker compose logs` still works. Docker
Desktop has no journald, so the local deploy keeps the default driver. Before
the first deploy with the driver, make sure that the docker daemon of the
host accepts it: `docker run --rm --log-driver journald alpine true`. Rails
writes to stdout, so all lines have the priority info; filter by text:

```sh
journalctl CONTAINER_NAME=mp-multitenancy-pl-web-1 --since yesterday -o cat | grep -A 25 FATAL
journalctl CONTAINER_NAME=mp-multitenancy-pl-worker-1 --since "2 days ago" -o cat
```

## Local deploy

`deploy-local.sh` deploys one variant and, for pl and marketplace, its hub on
a developer machine. The script uses the same compose files, builds the
images from the working tree and sets localhost URLs. The script does not
update the checkout, takes no lock and writes no state file. The header of
the script describes the layout under `tmp/local-deploy`, the env files that
the script writes on the first run and the ports: the slot of the variant
gives the instance port 30NN, the hub port 32NN, the transform API port 81NN
and the Solr port 89NN. On an arm64 host the script adds
`docker-compose-local-arm64.yml`, which replaces the Elasticsearch image with
the arm64 image of the development setup.

```sh
./lib/versions/deploy-local.sh pl                   # pl instance and pl hub
./lib/versions/deploy-local.sh --no-hub whitelabel  # instance only
./lib/versions/deploy-local.sh seed pl              # full load of Solr again
./lib/versions/deploy-local.sh down pl              # remove both projects
```

Without a dump at `tmp/local-deploy/seed/<variant>/mp_db.sql` the database
gets the schema of `db/schema.rb` and stays empty. A plain dump of the
development database of the variant (`run_variant_env.sh` names the
databases) fills the instance with the development data:

```sh
mkdir -p tmp/local-deploy/seed/pl
docker exec <postgres container> pg_dump -U mp --no-owner --no-acl mp_pl_dump \
  > tmp/local-deploy/seed/pl/mp_db.sql
```

The full load of Solr needs `MP_API_TOKEN` in `tmp/local-deploy/hubs/<variant>.env`,
the token of a coordinator of the local instance. The script skips the load
while the variable is empty; `seed <variant>` starts the load later. The
script clones the hub checkouts once and does not update them: run `git pull`
in `tmp/local-deploy/hubs/<name>` for a newer version. The `MP VERSION` line
of the page source reads `mp-local-<variant> <commit>`, with `-dirty` when
tracked files of the working tree are changed.

## GitHub Actions

No workflow exists yet. The goal is a workflow that deploys the staging
environment after a push to the deploy branch:

- A push runs `deploy-multi.sh --ref <commit of the push>`, then
  `deploy-hubs.sh`, on the host. The commit argument deploys the pushed
  commit, not the tip of the branch at the time of the run. A manual run
  (`workflow_dispatch`) takes the variants, the mode and the force flag as
  inputs. A run of the commit that is already deployed prints "Up-to-date",
  so a manual run of the same commit needs the force flag.
- A push to a hub repository, to the transform service or to a commons
  repository does not reach this repository. Those changes deploy with a
  manual run, or with a `repository_dispatch` event from that repository.
- The job runs on the host: with a self-hosted runner on the host, or with an
  SSH connection from a hosted runner. The decision is open. A self-hosted
  runner needs an outbound connection only. An SSH connection needs an inbound
  port on the host and a key in the repository secrets. In both cases the user
  of the job needs the group of ROOT and the group `docker`.
- A `concurrency` group serializes the runs of the workflow. The lock of the
  scripts stays as a safeguard: a parallel run fails.

Open point before the workflow: ROOT is the parent of the checkout of the
script. A checkout of `actions/checkout` on a self-hosted runner lies in the
work directory of the runner, without the seed, the env files and the state
file, and the compose files read `marketplace-<variant>.env` next to them.
Either the workflow runs the scripts of the host checkout, or the scripts read
ROOT from `MP_ROOT_DIR`.
