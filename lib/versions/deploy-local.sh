#!/bin/bash
# Deploys one deployment variant of this repository (marketplace, pl or
# whitelabel) and, for pl and marketplace, its discovery hub on the local
# machine with docker compose. The compose files are those of the staging
# deploy (docker-compose-<variant>.yml, docker-compose-hub-<variant>.yml), the
# images are built from the working tree and the URLs point to localhost.
# The script is for a developer machine: no update of the checkout, no lock
# and no state file. lib/versions/deploy-multi.sh and deploy-hubs.sh deploy
# the staging host.
#
# Layout under MP_LOCAL_DIR (default: tmp/local-deploy of this checkout):
#   seed/<variant>/mp_db.sql     plain SQL dump, optional. Without a dump the
#                                database gets the schema of db/schema.rb and
#                                stays empty.
#   seed/<variant>/media/        media files, optional
#   hubs/<variant>               checkout of the hub, cloned on the first run.
#                                The script does not update the checkouts.
#   hubs/transform-service       checkout of the transform service
#   hubs/eosc-pl-common          commons checkout of the pl hub
#   hubs/eosc-portal-common      commons checkout of the marketplace hub
#   hubs/<variant>.env           settings of the hub, created on the first run.
#                                The full load of Solr needs MP_API_TOKEN, the
#                                token of a coordinator of the local instance.
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
# Usage:  deploy-local.sh [up|down|seed] [--no-hub] <variant>
#   up (default)  -> build the images and start the instance, then the hub;
#                    seed the database and Solr on the first run
#   down          -> remove the instance and the hub: containers, images, volumes
#   seed          -> create the Solr collections if absent, then start a full load
#   --no-hub      -> the instance only
# The script exits with status 1 when a step failed.
# Examples:
#   deploy-local.sh pl                  # pl instance and pl hub
#   deploy-local.sh --no-hub whitelabel # whitelabel instance
#   deploy-local.sh seed pl             # load the pl hub's Solr again
#   deploy-local.sh down pl             # remove the pl instance and the pl hub
set -uo pipefail

APP=$(git -C "$(dirname "$0")" rev-parse --show-toplevel) || exit 1
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
for arg in "$@"; do
    case "$arg" in
        up|down|seed) MODE="$arg" ;;
        --no-hub) WITH_HUB=0 ;;
        -h|--help)
            echo "Usage: $0 [up|down|seed] [--no-hub] <${ALL_VARIANTS[*]}>"; exit 0 ;;
        *)
            if [[ " ${ALL_VARIANTS[*]} " == *" $arg "* ]] && [ -z "$VARIANT" ]; then
                VARIANT="$arg"
            else
                echo "Unknown argument: $arg (one variant of: ${ALL_VARIANTS[*]})"; exit 2
            fi ;;
    esac
done
[ -n "$VARIANT" ] || { echo "Usage: $0 [up|down|seed] [--no-hub] <${ALL_VARIANTS[*]}>"; exit 2; }
[[ " ${HUB_VARIANTS[*]} " == *" $VARIANT "* ]] || WITH_HUB=0

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

instance() {
    COMPOSE_PROJECT_NAME="${COMPOSE_PREFIX}-${VARIANT}" \
        "$DC" compose "${INSTANCE_FILES[@]}" "$@"
}
hub() {
    COMPOSE_PROJECT_NAME="${COMPOSE_PREFIX}-${VARIANT}-hub" \
        "$DC" compose -f "docker-compose-hub-${VARIANT}.yml" "$@"
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

# Clones the repository on the first run. An existing checkout stays as it is.
clone_checkout() {
    local name="$1"
    local checkout="$HUBS/$name"
    [ -d "$checkout/.git" ] && return 0
    echo "cloning $(repository_url "$name") ($(repository_branch "$name")) to $checkout"
    git clone -q -b "$(repository_branch "$name")" "$(repository_url "$name")" "$checkout"
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
            instance run --rm -e DISABLE_DATABASE_ENVIRONMENT_CHECK=1 "$APP_SERVICE" \
                ./bin/rails db:schema:load || return 1
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

    clone_checkout "$VARIANT" || return 1
    clone_checkout transform-service || return 1
    clone_checkout "$(commons_repository "$VARIANT")" || return 1
    install_commons_environment || return 1

    hub build || return 1
    hub up -d --remove-orphans || return 1
    seed_hub first
}

case "$MODE" in
    down)
        status=0
        echo "=== [${VARIANT}] down ==="
        instance down -v --remove-orphans --rmi local || { echo "[${VARIANT}] down FAILED"; status=1; }
        if [ "$WITH_HUB" = 1 ]; then
            echo "=== [${VARIANT} hub] down ==="
            hub down -v --remove-orphans --rmi local || { echo "[${VARIANT} hub] down FAILED"; status=1; }
        fi
        exit $status ;;
    seed)
        [ "$WITH_HUB" = 1 ] || { echo "no hub for ${VARIANT}"; exit 2; }
        echo "=== [${VARIANT} hub] seed ==="
        seed_hub always || { echo "[${VARIANT} hub] seed FAILED"; exit 1; }
        exit 0 ;;
esac

echo "=== [${VARIANT}] deploy ==="
deploy_instance || { echo "[${VARIANT}] FAILED"; exit 1; }
echo "[${VARIANT}] instance: $MP_ROOT_URL"
if [ "$WITH_HUB" = 1 ]; then
    echo "=== [${VARIANT} hub] deploy ==="
    deploy_hub || { echo "[${VARIANT} hub] FAILED"; exit 1; }
    echo "[${VARIANT}] hub: $MP_HUB_URL"
fi
