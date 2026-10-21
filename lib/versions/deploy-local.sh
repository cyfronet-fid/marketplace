#!/bin/bash
# Deploys one deployment variant of this repository (marketplace, pl or
# whitelabel) and, for pl and marketplace, its discovery hub on the local
# machine with docker compose. The compose files are those of the staging
# deploy (docker-compose-<variant>.yml, docker-compose-hub-<variant>.yml) and
# the URLs point to localhost.
# By default the instance runs the development environment on the working
# tree (lib/versions/docker-compose-local-dev.yml): Rails reloads a code
# change on the next request, the watchers build the js and the css on
# change, and `restart` applies a change of Gemfile, package.json or an
# initializer. With --production the instance runs the production images of
# the staging deploy, built from the working tree. The hub always runs its
# production images, built from the hub checkouts.
# The script is for a developer machine: no update of the checkout, no lock
# and no state file. lib/versions/deploy-multi.sh and deploy-hubs.sh deploy
# the staging host.
#
# Layout under MP_LOCAL_DIR (default: tmp/local-deploy of this checkout):
#   seed/<variant>/mp_db.sql     plain SQL dump, optional. Without a dump the
#                                database gets the schema of db/schema.rb and
#                                stays empty.
#   seed/<variant>/media/        media files, optional
#   hubs/<name>                  symlinks to the hub checkouts, with the names
#                                that the hub compose file expects
#   hubs/<variant>.env           settings of the hub, created on the first run.
#                                The full load of Solr needs MP_API_TOKEN, the
#                                token of a coordinator of the local instance.
# The hub code comes from the checkouts next to this repository
# (MP_WORKSPACE=<dir> points to another directory): pl-discovery-hub,
# eosc-search-service, transform-service, eosc-pl-common and
# eosc-portal-common. The script never updates the checkouts and builds the
# hub from their current state, local changes included. A missing checkout is
# an error; with --clone the script clones it there. The deploy copies the
# commons environment (lib/versions/hub/commons/<variant>) into the commons
# checkout as untracked files, as the staging deploy does.
# marketplace-<variant>.env in this checkout holds the settings of the
# instance. The script creates a minimal file on the first run: the
# application starts, Check-in does not work with the placeholders.
#
# On an arm64 host (Apple silicon) docker-compose-local-arm64.yml replaces the
# Elasticsearch image, which has no arm64 build, with the image of the
# development setup.
#
# URLs and ports, from the slot of lib/versions/staging-urls.sh:
#   instance       http://localhost:30<slot>  pl 3016, whitelabel 3017, marketplace 3018
#   hub            http://localhost:32<slot>  pl 3216, marketplace 3218
#   transform api  127.0.0.1:81<slot>, Solr 127.0.0.1:89<slot>
# MP_LOCAL_HOST=<name> replaces localhost in the URLs.
#
# Usage:  deploy-local.sh [up|down|seed|restart] [--no-hub|--no-instance]
#                         [--no-transform] [--production] <variant>
#   up (default)  -> build the images and start the instance, then the hub;
#                    seed the database and Solr on the first run. Without a
#                    flag this sets up everything of one variant at once.
#   restart       -> restart the web, worker and assets containers of the
#                    instance, to apply a change of Gemfile, package.json or
#                    an initializer. A plain code change needs no restart.
#   down          -> remove the instance and the hub: containers, images, volumes
#   seed          -> create the Solr collections if absent, then start a full
#                    load; starts the transform services when they are absent.
#                    A full load takes a long time and runs in the background:
#                    watch the transform-worker log.
#   --no-hub      -> the instance only
#   --no-instance -> the hub only (pl and marketplace); the full load of Solr
#                    needs the running instance
#   --no-transform -> up without the transform services (transform-api,
#                    transform-worker, redis) and without a seed, Solr keeps
#                    its data. For a hub after the first full load; `seed`
#                    starts the services again.
#   --production  -> the instance runs the production images of the staging
#                    deploy instead of the development environment
#   --clone       -> clone a missing hub checkout next to this repository
# The script exits with status 1 when a step failed.
# Examples:
#   deploy-local.sh pl                  # everything of pl: instance and hub
#   deploy-local.sh restart pl          # apply a Gemfile or initializer change
#   deploy-local.sh --no-hub whitelabel # whitelabel instance
#   deploy-local.sh --no-instance pl    # pl hub only
#   deploy-local.sh --no-transform pl   # pl without the transform services
#   deploy-local.sh --production pl     # the staging images, built from the tree
#   deploy-local.sh seed pl             # load the pl hub's Solr again
#   deploy-local.sh down pl             # remove the pl instance and the pl hub
set -uo pipefail

APP=$(git -C "$(dirname "$0")" rev-parse --show-toplevel) || exit 1
# ROOT holds the hub checkouts, next to this repository.
ROOT="${MP_WORKSPACE:-$(dirname "$APP")}"
LOCAL_DIR="${MP_LOCAL_DIR:-$APP/tmp/local-deploy}"
HUBS="$LOCAL_DIR/hubs"
SEED_DIR="$LOCAL_DIR/seed"
HOST="${MP_LOCAL_HOST:-localhost}"
# staging_slot: the slot of a variant, the ports follow it.
# shellcheck source=staging-urls.sh
. "$APP/lib/versions/staging-urls.sh" || exit 1

# ---------------------------------------------------------------------------
# Configuration (the service names repeat the compose files)
# ---------------------------------------------------------------------------
ALL_VARIANTS=(marketplace pl whitelabel)
HUB_VARIANTS=(pl marketplace)
COMPOSE_PREFIX="mp-local"
DB_SERVICE="db"
DB_USER="mp"
DB_NAME="mp_production"
APP_SERVICE="web"
MEDIA_PATH="/marketplace/media"
WAIT_TIMEOUT=300            # seconds to wait for the database, Solr and the collections

repository_url() {
    case "$1" in
        pl)                 echo "https://github.com/cyfronet-fid/pl-discovery-hub.git" ;;
        marketplace)        echo "https://github.com/cyfronet-fid/eosc-search-service.git" ;;
        transform-service)  echo "https://github.com/cyfronet-fid/transform-service.git" ;;
        eosc-pl-common)     echo "https://github.com/cyfronet-fid/eosc-pl-common.git" ;;
        eosc-portal-common) echo "https://github.com/cyfronet-fid/eosc-portal-common.git" ;;
    esac
}
repository_branch() {
    case "$1" in
        eosc-pl-common)     echo "master" ;;
        eosc-portal-common) echo "develop" ;;
        *)                  echo "development" ;;
    esac
}
commons_repository() {
    case "$1" in
        pl)          echo "eosc-pl-common" ;;
        marketplace) echo "eosc-portal-common" ;;
    esac
}
collections_prefix() {
    case "$1" in
        pl)          echo "pl_" ;;
        marketplace) echo "" ;;
    esac
}
# ---------------------------------------------------------------------------

MODE="up"
VARIANT=""
WITH_HUB=1
WITH_INSTANCE=1
TRANSFORM=1
PRODUCTION=0
CLONE=0
USAGE="Usage: $0 [up|down|seed|restart] [--no-hub|--no-instance] [--no-transform] [--production] [--clone] <${ALL_VARIANTS[*]}>"
for arg in "$@"; do
    case "$arg" in
        up|down|seed|restart) MODE="$arg" ;;
        --no-hub) WITH_HUB=0 ;;
        --no-instance) WITH_INSTANCE=0 ;;
        --no-transform) TRANSFORM=0 ;;
        --production) PRODUCTION=1 ;;
        --clone) CLONE=1 ;;
        -h|--help)
            echo "$USAGE"; exit 0 ;;
        *)
            if [[ " ${ALL_VARIANTS[*]} " == *" $arg "* ]] && [ -z "$VARIANT" ]; then
                VARIANT="$arg"
            else
                echo "Unknown argument: $arg (one variant of: ${ALL_VARIANTS[*]})"; exit 2
            fi ;;
    esac
done
[ -n "$VARIANT" ] || { echo "$USAGE"; exit 2; }
if [ "$WITH_HUB" = 0 ] && [ "$WITH_INSTANCE" = 0 ]; then
    echo "--no-hub and --no-instance exclude each other"; exit 2
fi
[[ " ${HUB_VARIANTS[*]} " == *" $VARIANT "* ]] || WITH_HUB=0
if [ "$WITH_INSTANCE" = 0 ] && [ "$WITH_HUB" = 0 ]; then
    echo "no hub for ${VARIANT}: nothing to deploy"; exit 2
fi
if [ "$TRANSFORM" = 0 ] && [ "$MODE" != "up" ]; then
    echo "--no-transform does not apply to $MODE"; exit 2
fi
if [ "$CLONE" = 1 ] && [ "$MODE" != "up" ]; then
    echo "--clone does not apply to $MODE"; exit 2
fi
if [ "$MODE" = "restart" ]; then
    [ "$WITH_INSTANCE" = 1 ] || { echo "--no-instance does not apply to restart"; exit 2; }
    [ "$PRODUCTION" = 0 ] || { echo "restart does not apply to --production: the image is fixed, deploy again"; exit 2; }
fi

# The transform services of the hub compose file have the compose profile
# "transform"; HUB_PROFILES activates it for every hub compose call. With
# --no-transform an up runs without the profile: the transform services are
# not built and not started. down and seed always need the profile: down
# removes the transform containers, seed starts them.
HUB_PROFILES="transform"
[ "$TRANSFORM" = 1 ] || HUB_PROFILES=""

DC=$(command -v docker) || { echo "docker not found"; exit 1; }
cd "$APP" || exit 1

SLOT=$(staging_slot "$VARIANT") || exit 1
export MP_ROOT_URL="http://${HOST}:30${SLOT}"
export MP_HUB_URL="http://${HOST}:32${SLOT}"
# The transform service reaches the instance from its container through the
# published port of the host.
export MP_API_URL="http://host.docker.internal:30${SLOT}"
TRANSFORM_PORT="81${SLOT}"
SOLR_PORT="89${SLOT}"
# The hub compose file takes the checkouts from MP_HUBS_DIR and the image
# recipes from MP_APP_DIR.
export MP_HUBS_DIR="$HUBS"
export MP_APP_DIR="$APP"
# MP_VERSION of the page source: the project and the commit of the working
# tree, with -dirty when tracked files are changed.
COMMIT_HASH=$(git rev-parse --verify HEAD)
git diff --quiet HEAD || COMMIT_HASH="${COMMIT_HASH}-dirty"
export COMMIT_HASH

# On an arm64 host the Elasticsearch image of the compose file has no build:
# lib/versions/docker-compose-local-arm64.yml replaces it.
INSTANCE_FILES=(-f "docker-compose-${VARIANT}.yml")
case "$(uname -m)" in
    arm64|aarch64) INSTANCE_FILES+=(-f lib/versions/docker-compose-local-arm64.yml) ;;
esac
# The development override: the instance runs the development environment on
# the working tree (see the header of the file). The assets service of the
# override reads the two MP_ variables; the variant compose file supplies
# them to web and worker. --production keeps the compose files of the
# staging deploy.
if [ "$PRODUCTION" = 0 ]; then
    INSTANCE_FILES+=(-f lib/versions/docker-compose-local-dev.yml)
    export MP_VARIANT="$VARIANT"
    case "$VARIANT" in
        marketplace) export MP_CUSTOMIZATION_PATH="" ;;
        *)           export MP_CUSTOMIZATION_PATH="/marketplace/customization/${VARIANT}" ;;
    esac
fi

instance() {
    COMPOSE_PROJECT_NAME="${COMPOSE_PREFIX}-${VARIANT}" \
        "$DC" compose "${INSTANCE_FILES[@]}" "$@"
}
hub() {
    COMPOSE_PROJECT_NAME="${COMPOSE_PREFIX}-${VARIANT}-hub" \
    COMPOSE_PROFILES="$HUB_PROFILES" \
        "$DC" compose -f "docker-compose-hub-${VARIANT}.yml" "$@"
}

# Stops and removes the transform containers of the hub, for an up with
# --no-transform. The profile must be active in the call, if not compose does
# not know the services. The volumes stay.
remove_transform() {
    HUB_PROFILES="transform" hub rm -sf transform-api transform-worker redis
}

# Writes a minimal marketplace-<variant>.env when the file is absent. The
# mandatory variables of .env.example get placeholders: the application
# starts, a login does not work.
write_instance_env() {
    local file="$APP/marketplace-${VARIANT}.env"
    [ -f "$file" ] && return 0
    echo "creating $file"
    {
        echo "# Settings of the local ${VARIANT} instance, written by lib/versions/deploy-local.sh."
        echo "# .env.example lists the variables. Check-in needs real values; the"
        echo "# placeholders let the application start without a login."
        echo "SECRET_KEY_BASE=$(openssl rand -hex 64)"
        echo "RECAPTCHA_ENABLED=false"
        if [[ " ${HUB_VARIANTS[*]} " == *" $VARIANT "* ]]; then
            echo "# The landing page renders the external search of the hub, as the"
            echo "# staging instance does. Remove the line for the internal search."
            echo "MP_ENABLE_EXTERNAL_SEARCH=true"
        fi
        if [ "$VARIANT" != "pl" ]; then
            echo "CHECKIN_ISSUER_URI=https://checkin.invalid/core"
            echo "CHECKIN_HOST=checkin.invalid"
            echo "CHECKIN_IDENTIFIER=local"
            echo "CHECKIN_SECRET=local"
            echo "CHECKIN_DISCOVERY=false"
        fi
        if [ "$VARIANT" = "marketplace" ]; then
            echo "BECOME_VO_MEMBER_URL=https://keycloak.invalid/vo"
            echo "VO_GROUP_NAME=local"
        fi
    } > "$file"
}

# Writes hubs/<variant>.env when the file is absent. MP_API_TOKEN stays empty:
# the full load of Solr waits for it.
write_hub_env() {
    local file="$HUBS/${VARIANT}.env"
    [ -f "$file" ] && return 0
    echo "creating $file"
    {
        echo "# Settings of the local ${VARIANT} hub, written by lib/versions/deploy-local.sh."
        echo "# The header of docker-compose-hub-${VARIANT}.yml lists the variables."
        echo "# MP_API_TOKEN is the token of a coordinator of the local instance. The"
        echo "# full load of Solr needs it: fill it in, then run deploy-local.sh seed ${VARIANT}."
        echo "MP_API_TOKEN="
        echo "SECRET_KEY=$(openssl rand -hex 32)"
        echo "OIDC_CLIENT_ID=local"
        echo "OIDC_CLIENT_SECRET=local"
        echo "LOG_LEVEL=INFO"
    } > "$file"
}

# The directory of a checkout in ROOT, named like the repository.
checkout_dir() {
    case "$1" in
        pl)          echo "$ROOT/pl-discovery-hub" ;;
        marketplace) echo "$ROOT/eosc-search-service" ;;
        *)           echo "$ROOT/$1" ;;
    esac
}

# Makes $HUBS/<name> a symlink to the checkout in ROOT, where the hub compose
# file expects it. The script never updates the checkouts. A missing checkout
# is an error; with --clone the script clones it into ROOT.
link_checkout() {
    local name="$1" dir link
    dir=$(checkout_dir "$name")
    link="$HUBS/$name"
    if [ ! -d "$dir/.git" ]; then
        if [ "$CLONE" = 1 ]; then
            echo "cloning $(repository_url "$name") ($(repository_branch "$name")) to $dir"
            git clone -q -b "$(repository_branch "$name")" "$(repository_url "$name")" "$dir" || return 1
        else
            echo "missing checkout $dir: clone it there or run with --clone"
            return 1
        fi
    fi
    if [ -d "$link" ] && [ ! -L "$link" ]; then
        echo "$link is a clone of an earlier run: remove it, the checkouts now live in $ROOT"
        return 1
    fi
    ln -sfn "$dir" "$link"
}

# Copies the staging environment of the commons (lib/versions/hub/commons/
# <variant>) into the commons checkout, where commons.Dockerfile builds it
# with the local URLs.
install_commons_environment() {
    local checkout="$HUBS/$(commons_repository "$VARIANT")"
    local source="$APP/lib/versions/hub/commons/$VARIANT"
    cp "$source/env.staging.js" "$checkout/env/" || return 1
    cp "$source"/*.json "$checkout/configurations/" || return 1
}

# Waits until the URL answers with 2xx, up to WAIT_TIMEOUT seconds.
wait_for_url() {
    local url="$1" waited=0
    until curl -sf -o /dev/null "$url"; do
        sleep 5
        waited=$((waited + 5))
        [ "$waited" -lt "$WAIT_TIMEOUT" ] || return 1
    done
}

# Creates the Solr collections when they are absent, then starts a full load
# from the marketplace API. With the argument "always" the load also starts
# when the collections exist. The load runs in the transform worker:
#   docker compose -p mp-local-<variant>-hub logs -f transform-worker
seed_hub() {
    local load="${1:-first}"
    local prefix solr transform
    prefix=$(collections_prefix "$VARIANT")
    solr="http://127.0.0.1:${SOLR_PORT}/solr"
    transform="http://127.0.0.1:${TRANSFORM_PORT}"

    wait_for_url "$solr/admin/collections?action=LIST" || { echo "Solr not ready"; return 1; }
    wait_for_url "$transform/docs" || { echo "transform service not ready"; return 1; }

    if curl -s "$solr/admin/collections?action=LIST" | grep -q "\"${prefix}all_collection\""; then
        echo "[${VARIANT} hub] collections present"
        [ "$load" = "always" ] || return 0
    else
        echo "[${VARIANT} hub] creating the collections (prefix '${prefix}')"
        # solr_url is passed although the service has it in its settings: the
        # endpoint rejects its own default (a URL object where a string is expected).
        curl -sf -X POST "$transform/create_collections?collection_prefix=${prefix}&solr_url=http://solr:8983/" || return 1
        echo
        wait_for_url "$solr/${prefix}all_collection/admin/ping" || { echo "collections not created, see the transform-worker log"; return 1; }
    fi

    if ! grep -qE '^MP_API_TOKEN=.+' "$HUBS/${VARIANT}.env"; then
        echo "[${VARIANT} hub] MP_API_TOKEN is empty in $HUBS/${VARIANT}.env: no full load."
        echo "Fill it in, then run: $0 seed ${VARIANT}"
        return 0
    fi
    echo "[${VARIANT} hub] full load from the marketplace API started:"
    curl -sf -X POST "$transform/full?data_type=all" || return 1
    echo
}

deploy_instance() {
    local compose_file="docker-compose-${VARIANT}.yml"
    local seed="$SEED_DIR/$VARIANT"
    local dump="$seed/mp_db.sql"

    [ -f "$compose_file" ] || { echo "missing $compose_file"; return 1; }
    write_instance_env || return 1

    # --- build the image, create the containers without a start ---
    instance build || return 1
    # The web container is created alone first: the creation fills the new
    # named volumes (bundle, node_modules) from the image. A parallel first
    # creation fills the same volume from two containers at once and fails
    # with "failed to mkdir ...: file exists".
    instance up --no-start "$APP_SERVICE" || return 1
    instance up --no-start --remove-orphans || return 1

    # --- start the database and wait for its healthcheck ---
    instance up -d --wait --wait-timeout "$WAIT_TIMEOUT" "$DB_SERVICE" || {
        echo "database not healthy"
        instance logs --tail=30 "$DB_SERVICE"
        return 1
    }

    # --- seed when the database has no schema_migrations table ---
    if [ "$(instance exec -T "$DB_SERVICE" psql -tA -U "$DB_USER" -d "$DB_NAME" \
            -c "SELECT to_regclass('public.schema_migrations') IS NOT NULL" 2>/dev/null)" = "t" ]; then
        echo "[${VARIANT}] database present, kept (reset with: $0 down ${VARIANT})"
    else
        if [ -d "$seed/media" ]; then
            instance cp "$seed/media/." "${APP_SERVICE}:${MEDIA_PATH}/" || return 1
        fi
        if [ -f "$dump" ]; then
            # The connection goes to the database "postgres": a database with
            # an open connection cannot be removed.
            echo "DROP DATABASE IF EXISTS ${DB_NAME}; CREATE DATABASE ${DB_NAME};" \
                | instance exec -T -e PGOPTIONS='-c client_min_messages=warning' "$DB_SERVICE" \
                    psql -q -v ON_ERROR_STOP=1 -U "$DB_USER" -d postgres > /dev/null || return 1
            instance exec -T -e PGOPTIONS='-c client_min_messages=warning' "$DB_SERVICE" \
                psql -q -v ON_ERROR_STOP=1 --single-transaction -U "$DB_USER" -d "$DB_NAME" -f - \
                < "$dump" > /dev/null || return 1
            echo "[${VARIANT}] database seeded from $dump"
        else
            echo "[${VARIANT}] no $dump: loading db/schema.rb into the empty database"
            # SCHEMA: the development override moves the schema dump away from
            # db/schema.rb; the load here has to read the repository's file.
            local schema_command=(./bin/rails db:schema:load)
            if [ "$PRODUCTION" = 0 ]; then
                # This one-off command replaces the web startup command, so
                # complete the fresh bundle volume before booting development.
                schema_command=(sh -c "bundle config set --local without '' && bundle install && exec ./bin/rails db:schema:load")
            fi
            instance run --rm -e DISABLE_DATABASE_ENVIRONMENT_CHECK=1 -e SCHEMA=db/schema.rb \
                "$APP_SERVICE" "${schema_command[@]}" || return 1
        fi
    fi

    # --- the rest of the application: migrations, reindex, puma ---
    instance up -d || return 1
}

deploy_hub() {
    local compose_file="docker-compose-hub-${VARIANT}.yml"
    [ -f "$compose_file" ] || { echo "missing $compose_file"; return 1; }
    mkdir -p "$HUBS" || return 1
    write_hub_env || return 1

    link_checkout "$VARIANT" || return 1
    link_checkout transform-service || return 1
    link_checkout "$(commons_repository "$VARIANT")" || return 1
    install_commons_environment || return 1

    hub build || return 1
    hub up -d --remove-orphans || return 1
    if [ "$TRANSFORM" = 0 ]; then
        remove_transform || return 1
        echo "[${VARIANT} hub] no transform services: no seed. Run: $0 seed ${VARIANT}"
        return 0
    fi
    seed_hub first
}

case "$MODE" in
    down)
        status=0
        if [ "$WITH_INSTANCE" = 1 ]; then
            echo "=== [${VARIANT}] down ==="
            instance down -v --remove-orphans --rmi local || { echo "[${VARIANT}] down FAILED"; status=1; }
        fi
        if [ "$WITH_HUB" = 1 ]; then
            echo "=== [${VARIANT} hub] down ==="
            hub down -v --remove-orphans --rmi local || { echo "[${VARIANT} hub] down FAILED"; status=1; }
        fi
        exit $status ;;
    seed)
        [ "$WITH_HUB" = 1 ] || { echo "no hub for ${VARIANT}"; exit 2; }
        echo "=== [${VARIANT} hub] seed ==="
        # The seed needs the transform service. The up starts it when it is
        # absent (after an up with --no-transform), with a build when
        # necessary, and does nothing when it runs.
        hub up -d transform-api transform-worker || { echo "[${VARIANT} hub] transform start FAILED"; exit 1; }
        seed_hub always || { echo "[${VARIANT} hub] seed FAILED"; exit 1; }
        exit 0 ;;
    restart)
        echo "=== [${VARIANT}] restart ==="
        instance restart "$APP_SERVICE" worker assets || { echo "[${VARIANT}] restart FAILED"; exit 1; }
        echo "[${VARIANT}] instance: $MP_ROOT_URL"
        exit 0 ;;
esac

if [ "$WITH_INSTANCE" = 1 ]; then
    echo "=== [${VARIANT}] deploy ==="
    deploy_instance || { echo "[${VARIANT}] FAILED"; exit 1; }
    echo "[${VARIANT}] instance: $MP_ROOT_URL"
fi
if [ "$WITH_HUB" = 1 ]; then
    echo "=== [${VARIANT} hub] deploy ==="
    deploy_hub || { echo "[${VARIANT} hub] FAILED"; exit 1; }
    echo "[${VARIANT}] hub: $MP_HUB_URL"
fi
