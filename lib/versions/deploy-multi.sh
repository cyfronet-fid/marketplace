#!/bin/bash
# Deploys the three deployment variants of this repository (marketplace, pl,
# whitelabel) as separate docker compose projects on one host. Written for a
# cron job on the staging host. The database and the media of a variant are
# seeded from ROOT/seed/<variant> on the first deploy only. Later deploys keep
# them (the web container runs the migrations), and `down <variant>` removes
# them, so the next deploy seeds again.
#
# Layout of the host directory (ROOT, the parent of this checkout). The script
# runs from lib/versions of the checkout or from a copy at ROOT/deploy-multi.sh;
# ROOT is derived from the location of the script in both cases.
#   ROOT/marketplace                   this repository, with one
#                                      docker-compose-<variant>.yml per variant
#   ROOT/seed/<variant>/mp_db.sql      plain SQL dump of the database
#   ROOT/seed/<variant>/media/         copied to MEDIA_PATH in the app container
#   ROOT/.last-deployed-commit         commit of the last complete deploy
#
# MP_SEED_DIR=<dir> points to another seed directory.
#
# Usage:  deploy-multi.sh [down] [-f|--force] [variant ...]
#   no variant           -> all variants (marketplace pl whitelabel), cron mode
#   -f / --force         -> deploy without the check for a new commit
#   with variants        -> only the given variants, forced deploy (no commit
#                           check) and no write of the state file
# Examples:
#   deploy-multi.sh                 # all variants, only when there are changes
#   deploy-multi.sh --force         # all variants, always
#   deploy-multi.sh pl              # forced deploy of pl only, the database stays
#   deploy-multi.sh down pl         # remove pl: containers, images, database, media
#   deploy-multi.sh down            # remove all variants
set -uo pipefail

# Cron has a minimal PATH.
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
# The host directory is shared by a group: files written here (the checkout,
# the state file) must stay writable for the other members.
umask 002

# A copy at ROOT/deploy-multi.sh has the checkout next to it; inside the
# checkout the repository is the git top level.
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
if [ -d "$SCRIPT_DIR/marketplace" ]; then
    APP="$SCRIPT_DIR/marketplace"
else
    APP=$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel) || exit 1
fi
ROOT=$(dirname "$APP")
cd "$ROOT" || exit 1

date

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
ALL_VARIANTS=(marketplace pl whitelabel)
COMPOSE_PREFIX="mp-multitenancy"

SEED_DIR="${MP_SEED_DIR:-$ROOT/seed}"
STATE_FILE="$ROOT/.last-deployed-commit"

# Adjust to the compose files:
DB_SERVICE="db"                 # name of the database service in the compose file
DB_USER="mp"                    # = POSTGRES_USER of the compose file (default mp)
DB_NAME="mp_production"
APP_SERVICE="web"               # application service of the compose file, the media go there
MEDIA_PATH="/marketplace/media" # path in the container
# ---------------------------------------------------------------------------

MODE="deploy"
VARIANTS=()
FORCE=0
PARTIAL=0
for arg in "$@"; do
    case "$arg" in
        down) MODE="down" ;;
        -f|--force) FORCE=1 ;;
        -h|--help)
            echo "Usage: $0 [down] [-f|--force] [${ALL_VARIANTS[*]}]"; exit 0 ;;
        *)
            if [[ " ${ALL_VARIANTS[*]} " == *" $arg "* ]]; then
                VARIANTS+=("$arg")
            else
                echo "Unknown argument: $arg (variants: ${ALL_VARIANTS[*]})"; exit 2
            fi ;;
    esac
done

if [ ${#VARIANTS[@]} -eq 0 ]; then
    VARIANTS=("${ALL_VARIANTS[@]}")
else
    FORCE=1
    PARTIAL=1
fi

# Lock against a parallel run. The lock is on the checkout directory, so every
# user who can read the directory shares the same lock, and no lock file has
# to be writable by all of them.
exec 9<"$APP"
flock -n 9 || { echo "Another deploy is running, exiting"; exit 0; }

cd "$APP" || exit 1

# ---------------------------------------------------------------------------
# Mode: deploy-multi.sh down [variant ...]
# Removes the containers, networks, volumes (the database included) and local
# images of the given variants (default: all). Also clears the state file, so
# the next run without an argument (for example from cron) does a full deploy
# from zero.
# ---------------------------------------------------------------------------
if [ "$MODE" = "down" ]; then
    export COMMIT_HASH="none"
    for variant in "${VARIANTS[@]}"; do
        export COMPOSE_PROJECT_NAME="${COMPOSE_PREFIX}-${variant}"
        echo "=== [${variant}] down ==="
        /usr/bin/docker compose -f "docker-compose-${variant}.yml" \
            down -v --remove-orphans --rmi local \
            || echo "[${variant}] down FAILED"
    done
    # Truncated, not removed: a removal needs write permission on ROOT, a
    # truncation only on the file.
    [ -f "$STATE_FILE" ] && : > "$STATE_FILE"
    echo "Down finished"
    exit 0
fi

# --- update the checkout to the remote branch ---
# The checkout is a deploy artifact, not a workspace: local commits and local
# changes to tracked files are discarded, untracked files (the env files)
# stay. The comparison of commits does not depend on the language of git's
# messages.
git fetch -q origin || { echo "git fetch failed"; exit 1; }
UPSTREAM=$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}') || { echo "no upstream branch"; exit 1; }
if [ "$(git rev-parse HEAD)" != "$(git rev-parse "$UPSTREAM")" ]; then
    git reset -q --hard "$UPSTREAM" || { echo "git reset failed"; exit 1; }
    echo "Updated to $UPSTREAM $(git rev-parse --short HEAD)"
fi

COMMIT_HASH=$(git rev-parse --verify HEAD)
export COMMIT_HASH

# The state file holds the commit of the last complete deploy. A failed variant
# is thus deployed again at the next run from cron, although the repository is
# already current.
if [ "$FORCE" = 0 ] && [ "$(cat "$STATE_FILE" 2>/dev/null)" = "$COMMIT_HASH" ]; then
    echo "Up-to-date"
    exit 0
fi

DC=/usr/bin/docker
failed=()

deploy_variant() {
    local variant="$1"
    local compose_file="docker-compose-${variant}.yml"
    local seed="${SEED_DIR}/${variant}"
    local dump=""

    export COMPOSE_PROJECT_NAME="${COMPOSE_PREFIX}-${variant}"
    local dc=("$DC" compose -f "$compose_file")

    # --- validation BEFORE any removal ---
    [ -f "$compose_file" ] || { echo "missing $compose_file"; return 1; }
    dump="$seed/mp_db.sql"
    [ -f "$dump" ] || { echo "missing $dump"; return 1; }

    # --- build the new image (the old environment still runs) ---
    "${dc[@]}" build || return 1

    # --- create the containers again, do not start them ---
    # The named volumes (database, media) stay. The anonymous volumes of the
    # old containers move to the new ones.
    "${dc[@]}" up --no-start --remove-orphans || return 1

    # --- start only the database and wait until it is healthy (healthcheck in compose) ---
    # --wait waits for the status "healthy" of the db service. The healthcheck
    # tests TCP, so it does not catch the temporary server of the initdb phase.
    # A healthcheck in the compose file is necessary.
    timeout 180 "${dc[@]}" up -d --wait "$DB_SERVICE" || {
        echo "database not healthy"
        "${dc[@]}" logs --tail=30 "$DB_SERVICE"
        return 1
    }

    # --- seed on the first deploy only ---
    # The postgres image creates an empty POSTGRES_DB at the initialization of
    # the volume, so the test is the schema_migrations table, not the database.
    if [ "$("${dc[@]}" exec -T "$DB_SERVICE" psql -tA -U "$DB_USER" -d "$DB_NAME" \
            -c "SELECT to_regclass('public.schema_migrations') IS NOT NULL" 2>/dev/null)" = "t" ]; then
        echo "[${variant}] database present, kept (reset with: $0 down ${variant})"
    else
        # --- copy the media from seed/<variant>/media to the application container ---
        # (the container exists after `up --no-start`; docker cp also writes to volumes)
        if [ -d "$seed/media" ]; then
            "${dc[@]}" cp "$seed/media/." "${APP_SERVICE}:${MEDIA_PATH}/" || return 1
        else
            echo "[${variant}] no $seed/media, skipping media copy"
        fi

        # --- create the database again ---
        # The connection goes to the database "postgres": a database with the
        # name of the user (mp) does not exist, and a database with an open
        # connection cannot be removed.
        echo "DROP DATABASE IF EXISTS ${DB_NAME}; CREATE DATABASE ${DB_NAME};" \
            | "${dc[@]}" exec -T -e PGOPTIONS='-c client_min_messages=warning' "$DB_SERVICE" \
                psql -q -v ON_ERROR_STOP=1 -U "$DB_USER" -d postgres > /dev/null || return 1

        # --- restore the dump in one transaction ---
        # A failed restore leaves the database empty, so the next deploy seeds
        # again. -q: no information messages, > /dev/null: no output of
        # set_config and similar. Errors go to stderr, so they stay visible;
        # NOTICE messages are silenced by PGOPTIONS.
        "${dc[@]}" exec -T -e PGOPTIONS='-c client_min_messages=warning' "$DB_SERVICE" \
            psql -q -v ON_ERROR_STOP=1 --single-transaction -U "$DB_USER" -d "$DB_NAME" -f - \
            < "$dump" > /dev/null || return 1
        echo "[${variant}] database seeded from $dump"
    fi

    # --- the rest of the application ---
    "${dc[@]}" up -d || return 1
}

for variant in "${VARIANTS[@]}"; do
    echo "=== [${variant}] deploy ==="
    if deploy_variant "$variant"; then
        echo "[${variant}] OK"
    else
        echo "[${variant}] FAILED"
        failed+=("$variant")
    fi
done

if [ ${#failed[@]} -gt 0 ]; then
    echo "Deploy finished with errors in: ${failed[*]}"
    exit 1
fi

# The state file is written only after a deploy of all variants.
if [ "$PARTIAL" = 0 ]; then
    echo "$COMMIT_HASH" > "$STATE_FILE"
fi
echo "Deploy finished successfully for: ${VARIANTS[*]}"
