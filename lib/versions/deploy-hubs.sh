#!/bin/bash
# Deploys the discovery hubs of the pl and marketplace variants as separate
# docker compose projects on the staging host, next to the marketplace
# instances of lib/versions/deploy-multi.sh. Written for a cron job.
#
#   variant      repository                                   compose file
#   pl           github.com/cyfronet-fid/pl-discovery-hub     docker-compose-hub-pl.yml
#                github.com/cyfronet-fid/eosc-pl-common       EOSC commons (header, footer)
#   marketplace  github.com/cyfronet-fid/eosc-search-service  docker-compose-hub-marketplace.yml
#                github.com/cyfronet-fid/eosc-portal-common   EOSC commons (header, footer)
#   (both)       github.com/cyfronet-fid/transform-service    fills Solr, one checkout
#
# Layout (ROOT is the parent of this checkout, as for deploy-multi.sh; the
# script runs from lib/versions of the checkout or from a copy at
# ROOT/deploy-hubs.sh):
#   ROOT/marketplace                 this repository, with the compose files
#   HUBS/<variant>                   checkout of the hub (cloned on the first run)
#   HUBS/transform-service           checkout of the transform service
#   HUBS/eosc-pl-common              checkout of the commons of the pl hub, with
#                                    the staging environment of
#                                    lib/versions/hub/commons/pl copied in
#   HUBS/eosc-portal-common          checkout of the commons of the marketplace
#                                    hub, with lib/versions/hub/commons/marketplace
#   HUBS/<variant>.env               settings and secrets of the hub, see the
#                                    header of its compose file
#   HUBS/.last-deployed-<variant>    commits (hub, transform service, commons)
#                                    and lib/versions/hub tree of the last
#                                    complete deploy
# HUBS is ROOT/hubs; MP_HUBS_DIR=<dir> points to another directory. The
# directory must exist and be writable by the user who runs the script.
#
# Each hub project has its own Solr. After the first deploy the script seeds
# it: the transform service creates the collections and loads the data from
# the marketplace API of the variant (a full load; research products from
# dumps are not loaded). The hub database and Solr live in named volumes;
# `down <variant>` removes them.
#
# Usage:  deploy-hubs.sh [down|seed] [-f|--force] [variant ...]
#   no variant           -> both hubs, cron mode: deploy when a commit changed
#   -f / --force         -> deploy without the check for a new commit
#   with variants        -> only the given hubs, forced deploy
#   seed [variant ...]   -> create the Solr collections (if missing) and run a
#                           full load, for example after `down`
# Examples:
#   deploy-hubs.sh                  # both hubs, only when there are changes
#   deploy-hubs.sh pl               # forced deploy of the pl hub
#   deploy-hubs.sh seed pl          # load the pl hub's Solr again
#   deploy-hubs.sh down marketplace # remove the marketplace hub: containers, images, volumes
set -uo pipefail

# Cron has a minimal PATH.
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
# The host directory is shared by a group.
umask 002

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
if [ -d "$SCRIPT_DIR/marketplace" ]; then
    APP="$SCRIPT_DIR/marketplace"
else
    APP=$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel) || exit 1
fi
ROOT=$(dirname "$APP")
HUBS="${MP_HUBS_DIR:-$ROOT/hubs}"

date

# ---------------------------------------------------------------------------
# Configuration (the ports and prefixes repeat the compose files)
# ---------------------------------------------------------------------------
ALL_VARIANTS=(pl marketplace)
COMPOSE_PREFIX="mp-multitenancy"
DC=/usr/bin/docker
SEED_TIMEOUT=300            # seconds to wait for Solr and for the collections

repository_url() {
    case "$1" in
        pl)                 echo "https://github.com/cyfronet-fid/pl-discovery-hub.git" ;;
        marketplace)        echo "https://github.com/cyfronet-fid/eosc-search-service.git" ;;
        transform-service)  echo "https://github.com/cyfronet-fid/transform-service.git" ;;
        eosc-pl-common)     echo "https://github.com/cyfronet-fid/eosc-pl-common.git" ;;
        eosc-portal-common) echo "https://github.com/cyfronet-fid/eosc-portal-common.git" ;;
    esac
}
# The hubs and the transform service deploy their development branch; the
# commons repositories have no such branch, their default branch is used.
repository_branch() {
    case "$1" in
        eosc-pl-common)     echo "master" ;;
        eosc-portal-common) echo "develop" ;;
        *)                  echo "development" ;;
    esac
}
# The commons repository (header and footer) of the hub, see the compose file.
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
transform_port() {
    case "$1" in
        pl)          echo 8116 ;;
        marketplace) echo 8118 ;;
    esac
}
solr_port() {
    case "$1" in
        pl)          echo 8916 ;;
        marketplace) echo 8918 ;;
    esac
}
# ---------------------------------------------------------------------------

MODE="deploy"
VARIANTS=()
FORCE=0
for arg in "$@"; do
    case "$arg" in
        down) MODE="down" ;;
        seed) MODE="seed" ;;
        -f|--force) FORCE=1 ;;
        -h|--help)
            echo "Usage: $0 [down|seed] [-f|--force] [${ALL_VARIANTS[*]}]"; exit 0 ;;
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
fi

[ -d "$HUBS" ] || { echo "missing hubs directory $HUBS (MP_HUBS_DIR)"; exit 1; }
# The compose files take the hub checkouts from MP_HUBS_DIR and the UI image
# recipe from MP_APP_DIR (this checkout).
export MP_HUBS_DIR="$HUBS"
export MP_APP_DIR="$APP"

# Lock against a parallel run, on the hubs directory (shared by every user
# who can read it); independent of the lock of deploy-multi.sh.
exec 9<"$HUBS"
flock -n 9 || { echo "Another hubs deploy is running, exiting"; exit 0; }

cd "$APP" || exit 1

compose() {
    local variant="$1"
    shift
    COMPOSE_PROJECT_NAME="${COMPOSE_PREFIX}-${variant}-hub" \
        "$DC" compose -f "docker-compose-hub-${variant}.yml" "$@"
}

# Clones the repository on the first run, then resets the checkout to the
# remote branch: the checkout is a deploy artifact, local changes are discarded.
update_checkout() {
    local name="$1"
    local checkout="$HUBS/$name"
    local branch
    branch=$(repository_branch "$name")

    if [ ! -d "$checkout/.git" ]; then
        git clone -q -b "$branch" "$(repository_url "$name")" "$checkout" || return 1
    fi
    git -C "$checkout" fetch -q origin || return 1
    git -C "$checkout" reset -q --hard "origin/$branch" || return 1
}

# Copies the staging environment of the commons of the variant
# (lib/versions/hub/commons/<variant>: env.staging.js and the configuration
# JSON files with the links of the staging hosts) into the checkout, where
# commons.Dockerfile builds it. The checkout is reset at every deploy, the
# copied files are untracked there and stay.
install_commons_environment() {
    local variant="$1"
    local checkout="$HUBS/$(commons_repository "$variant")"
    local source="$APP/lib/versions/hub/commons/$variant"
    cp "$source/env.staging.js" "$checkout/env/" || return 1
    cp "$source"/*.json "$checkout/configurations/" || return 1
}

# Waits until the URL answers with 2xx, up to SEED_TIMEOUT seconds.
wait_for_url() {
    local url="$1" waited=0
    until curl -sf -o /dev/null "$url"; do
        sleep 5
        waited=$((waited + 5))
        [ "$waited" -lt "$SEED_TIMEOUT" ] || return 1
    done
}

# Creates the Solr collections of the variant through the transform service
# (the configset names come from the service's environment in the compose
# file), waits for them, then starts a full load from the marketplace API.
# The load runs in the transform worker: watch it with
#   docker compose -f docker-compose-hub-<variant>.yml logs -f transform-worker
seed_hub() {
    local variant="$1"
    local prefix solr transform
    prefix=$(collections_prefix "$variant")
    solr="http://127.0.0.1:$(solr_port "$variant")/solr"
    transform="http://127.0.0.1:$(transform_port "$variant")"

    wait_for_url "$solr/admin/collections?action=LIST" || { echo "Solr not ready"; return 1; }
    wait_for_url "$transform/docs" || { echo "transform service not ready"; return 1; }

    if curl -s "$solr/admin/collections?action=LIST" | grep -q "\"${prefix}all_collection\""; then
        echo "[${variant} hub] collections present"
    else
        echo "[${variant} hub] creating the collections (prefix '${prefix}')"
        # solr_url is passed although the service has it in its settings: the
        # endpoint rejects its own default (a URL object where a string is expected).
        curl -sf -X POST "$transform/create_collections?collection_prefix=${prefix}&solr_url=http://solr:8983/" || return 1
        echo
        wait_for_url "$solr/${prefix}all_collection/admin/ping" || { echo "collections not created, see the transform-worker log"; return 1; }
    fi

    echo "[${variant} hub] full load from the marketplace API started:"
    curl -sf -X POST "$transform/full?data_type=all" || return 1
    echo
}

# ---------------------------------------------------------------------------
# Mode: deploy-hubs.sh down [variant ...]
# Removes the containers, networks, volumes (database and Solr included) and
# local images of the given hubs (default: both), and clears their state files.
# ---------------------------------------------------------------------------
if [ "$MODE" = "down" ]; then
    for variant in "${VARIANTS[@]}"; do
        echo "=== [${variant} hub] down ==="
        compose "$variant" down -v --remove-orphans --rmi local \
            || echo "[${variant} hub] down FAILED"
        state="$HUBS/.last-deployed-${variant}"
        [ -f "$state" ] && : > "$state"
    done
    echo "Down finished"
    exit 0
fi

# ---------------------------------------------------------------------------
# Mode: deploy-hubs.sh seed [variant ...]
# ---------------------------------------------------------------------------
if [ "$MODE" = "seed" ]; then
    status=0
    for variant in "${VARIANTS[@]}"; do
        echo "=== [${variant} hub] seed ==="
        seed_hub "$variant" || { echo "[${variant} hub] seed FAILED"; status=1; }
    done
    exit $status
fi

failed=()

deploy_hub() {
    local variant="$1"
    local compose_file="docker-compose-hub-${variant}.yml"
    local env_file="$HUBS/${variant}.env"
    local state="$HUBS/.last-deployed-${variant}"
    local commit first_deploy=0

    # --- validation BEFORE any change ---
    [ -f "$compose_file" ] || { echo "missing $compose_file"; return 1; }
    [ -f "$env_file" ] || { echo "missing $env_file"; return 1; }

    local commons
    commons=$(commons_repository "$variant")
    update_checkout "$variant" || { echo "checkout update failed"; return 1; }
    update_checkout transform-service || { echo "transform-service update failed"; return 1; }
    update_checkout "$commons" || { echo "$commons update failed"; return 1; }
    install_commons_environment "$variant" || { echo "copy of the commons environment failed"; return 1; }
    # The state holds the three checkouts and the tree of lib/versions/hub
    # (image recipes, nginx and the commons environment of this repository),
    # so a change of any of them deploys in cron mode.
    commit="$(git -C "$HUBS/$variant" rev-parse --verify HEAD) $(git -C "$HUBS/transform-service" rev-parse --verify HEAD) $(git -C "$HUBS/$commons" rev-parse --verify HEAD) $(git -C "$APP" rev-parse --verify HEAD:lib/versions/hub)"

    if [ "$FORCE" = 0 ] && [ "$(cat "$state" 2>/dev/null)" = "$commit" ]; then
        echo "[${variant} hub] up-to-date at ${commit:0:8}"
        return 0
    fi
    [ -s "$state" ] || first_deploy=1

    # --- build the new images (the old environment still runs) ---
    compose "$variant" build || return 1

    # --- recreate the containers; the named volumes stay ---
    compose "$variant" up -d --remove-orphans || return 1

    echo "$commit" > "$state"
    echo "[${variant} hub] deployed ${commit:0:8}"

    if [ "$first_deploy" = 1 ]; then
        seed_hub "$variant" || return 1
    fi
}

for variant in "${VARIANTS[@]}"; do
    echo "=== [${variant} hub] deploy ==="
    if deploy_hub "$variant"; then
        echo "[${variant} hub] OK"
    else
        echo "[${variant} hub] FAILED"
        failed+=("$variant")
    fi
done

if [ ${#failed[@]} -gt 0 ]; then
    echo "Deploy finished with errors in: ${failed[*]}"
    exit 1
fi
echo "Deploy finished successfully for: ${VARIANTS[*]}"
