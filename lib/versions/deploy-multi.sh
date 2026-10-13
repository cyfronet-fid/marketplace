#!/bin/bash
# Deploys the three deployment variants of this repository (marketplace, pl,
# whitelabel) as separate docker compose projects on one host. The script runs
# by hand on the staging host, from a GitHub Actions job or on a local
# machine. The database and the media of a variant are seeded from
# ROOT/seed/<variant> on the first deploy only. Later deploys keep them (the
# web container runs the migrations), and `down <variant>` removes them, so
# the next deploy seeds again.
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
# MP_SEED_DIR=<dir> points to another seed directory. The public URLs of the
# instances and of their discovery hubs, which the compose files read from
# the environment, come from lib/versions/staging-urls.sh of the checkout.
#
# Usage:  deploy-multi.sh [down] [-f|--force] [--ref <commit>|--no-update] [variant ...]
#   no variant           -> all variants (marketplace pl whitelabel), only when
#                           the commit differs from the last complete deploy
#   -f / --force         -> deploy without the check for a new commit
#   --ref <commit>       -> reset the checkout to this commit instead of the
#                           upstream branch (a workflow gives the pushed commit)
#   --no-update          -> no fetch and no reset, deploy the checkout as it is
#                           (a local run with uncommitted changes)
#   with variants        -> only the given variants, forced deploy (no commit
#                           check) and no write of the state file
# The script exits with status 1 when a variant failed, when `down` failed or
# when another deploy holds the lock, and with status 0 when there was nothing
# to do.
# Examples:
#   deploy-multi.sh                 # all variants, only when there are changes
#   deploy-multi.sh --force         # all variants, always
#   deploy-multi.sh --ref 1a2b3c4   # all variants at the commit, the workflow call
#   deploy-multi.sh pl              # forced deploy of pl only, the database stays
#   deploy-multi.sh --no-update pl  # pl from the checkout as it is, a local run
#   deploy-multi.sh down pl         # remove pl: containers, images, database, media
#   deploy-multi.sh down            # remove all variants
set -uo pipefail

# A fixed PATH, independent of the caller (a shell, a workflow runner).
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
# shellcheck source=staging-urls.sh
. "$APP/lib/versions/staging-urls.sh" || exit 1

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

# The arguments are kept for the restart after a change of the script.
ARGS=("$@")
MODE="deploy"
VARIANTS=()
FORCE=0
PARTIAL=0
REF=""
UPDATE=1
while [ $# -gt 0 ]; do
    case "$1" in
        down) MODE="down" ;;
        -f|--force) FORCE=1 ;;
        --ref)
            [ $# -ge 2 ] || { echo "--ref needs a commit"; exit 2; }
            REF="$2"; shift ;;
        --no-update) UPDATE=0 ;;
        -h|--help)
            echo "Usage: $0 [down] [-f|--force] [--ref <commit>|--no-update] [${ALL_VARIANTS[*]}]"; exit 0 ;;
        *)
            if [[ " ${ALL_VARIANTS[*]} " == *" $1 "* ]]; then
                VARIANTS+=("$1")
            else
                echo "Unknown argument: $1 (variants: ${ALL_VARIANTS[*]})"; exit 2
            fi ;;
    esac
    shift
done
if [ -n "$REF" ] && [ "$UPDATE" = 0 ]; then
    echo "--ref and --no-update exclude each other"; exit 2
fi

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
flock -n 9 || { echo "Another deploy is running, exiting"; exit 1; }

cd "$APP" || exit 1

# ---------------------------------------------------------------------------
# Mode: deploy-multi.sh down [variant ...]
# Removes the containers, networks, volumes (the database included) and local
# images of the given variants (default: all). Also clears the state file, so
# the next run without an argument does a full deploy from zero.
# ---------------------------------------------------------------------------
if [ "$MODE" = "down" ]; then
    export COMMIT_HASH="none"
    failed=()
    for variant in "${VARIANTS[@]}"; do
        export COMPOSE_PROJECT_NAME="${COMPOSE_PREFIX}-${variant}"
        echo "=== [${variant}] down ==="
        if export_staging_urls "$variant" \
            && /usr/bin/docker compose -f "docker-compose-${variant}.yml" \
                down -v --remove-orphans --rmi local; then
            echo "[${variant}] removed"
        else
            echo "[${variant}] down FAILED"
            failed+=("$variant")
        fi
    done
    # Truncated, not removed: a removal needs write permission on ROOT, a
    # truncation only on the file.
    [ -f "$STATE_FILE" ] && : > "$STATE_FILE"
    if [ ${#failed[@]} -gt 0 ]; then
        echo "Down finished with errors in: ${failed[*]}"
        exit 1
    fi
    echo "Down finished"
    exit 0
fi

# --- update the checkout ---
# The checkout is a deploy artifact, not a workspace: local commits and local
# changes to tracked files are discarded, untracked files (the env files)
# stay. --no-update keeps the checkout as it is, for a local run. The target
# is the upstream branch or the commit of --ref: a workflow deploys the commit
# of its push, not the tip of the branch at the time of the run. The reset
# moves the current branch to the target, so the next run without --ref
# follows the upstream branch again.
if [ "$UPDATE" = 1 ]; then
    git fetch -q origin || { echo "git fetch failed"; exit 1; }
    if [ -n "$REF" ]; then
        TARGET=$(git rev-parse --verify --quiet "${REF}^{commit}") || { echo "unknown commit: $REF"; exit 1; }
    else
        TARGET=$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}') || { echo "no upstream branch"; exit 1; }
    fi
    if [ "$(git rev-parse HEAD)" != "$(git rev-parse "$TARGET")" ]; then
        # Bash reads the script file while the script runs, and staging-urls.sh
        # is already sourced. After the reset the old body of the two files is
        # in effect. When the reset changed one of them, the new script starts
        # again with the same arguments: it finds the checkout at the target
        # and continues. MP_DEPLOY_RESTARTED prevents a second restart.
        script_files=(lib/versions/deploy-multi.sh lib/versions/staging-urls.sh)
        old_scripts=$(git rev-parse "${script_files[@]/#/HEAD:}" 2>/dev/null)
        git reset -q --hard "$TARGET" || { echo "git reset failed"; exit 1; }
        echo "Updated to $TARGET $(git rev-parse --short HEAD)"
        new_scripts=$(git rev-parse "${script_files[@]/#/HEAD:}" 2>/dev/null)
        if [ "$old_scripts" != "$new_scripts" ] && [ -z "${MP_DEPLOY_RESTARTED:-}" ]; then
            echo "The deploy script changed, starting the new version"
            export MP_DEPLOY_RESTARTED=1
            exec "$APP/lib/versions/deploy-multi.sh" "${ARGS[@]}"
        fi
    fi
fi

COMMIT_HASH=$(git rev-parse --verify HEAD)
export COMMIT_HASH

# The state file holds the commit of the last complete deploy. A failed variant
# is thus deployed again at the next run, although the repository is already
# current.
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
    export_staging_urls "$variant" || return 1
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
