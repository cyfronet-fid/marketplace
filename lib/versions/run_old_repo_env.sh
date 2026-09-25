#!/bin/zsh
# Runs one of the OLD repositories (pl-marketplace, whitelabel-marketplace) next
# to the consolidated code started by run_variant_env.sh, to compare pages side
# by side. Own database, search server, redis database and web port, so both
# can run at the same time and nothing touches mp_development:
#
#   repo        directory               database         elasticsearch (container, port)  redis db  web port
#   pl          pl-marketplace          mp_pl_old_repo   mp-pl-old-el          9204        8         5001
#   whitelabel  whitelabel-marketplace  mp_wl_old_repo   mp-whitelabel-old-el  9205        9         5002
#
# Ruby comes from the repository's .ruby-version through rbenv (the script only
# makes sure no inherited RBENV_VERSION overrides it).
#
# Usage:
#   run_old_repo_env.sh <pl|whitelabel>                    start web, sidekiq and the css/js watchers
#   run_old_repo_env.sh <pl|whitelabel> restore <dump.sql> recreate the database from a plain SQL dump,
#                                                          run the old repository's migrations, reindex
#   run_old_repo_env.sh <pl|whitelabel> <command...>       any command in the same environment
#
# The old repository's .env is left alone. Foreman is started with an empty env
# file instead, because foreman lets .env win over exported variables (it sets
# ELASTICSEARCH_URL there); Rails' dotenv does not override what is exported.
#
# The old repositories are looked up in the directory that holds this
# repository; MP_WORKSPACE=<dir> points to another one.
set -e
ROOT=${MP_WORKSPACE:-${0:A:h:h:h:h}}
DB_CONTAINER=marketplace-db-1

case $1 in
  pl)         REPO=pl-marketplace;         DB=mp_pl_old_repo; ES_CONTAINER=mp-pl-old-el;         ES_PORT=9204; REDIS_DB=8; WEB_PORT=5001 ;;
  whitelabel) REPO=whitelabel-marketplace; DB=mp_wl_old_repo; ES_CONTAINER=mp-whitelabel-old-el; ES_PORT=9205; REDIS_DB=9; WEB_PORT=5002 ;;
  *) echo "usage: run_old_repo_env.sh <pl|whitelabel> [restore <dump.sql> | <command...>]"; exit 1 ;;
esac
shift

unset RBENV_VERSION
export DATABASE_URL=postgres://mp:mp@127.0.0.1:5432/$DB
export ELASTICSEARCH_URL=http://127.0.0.1:$ES_PORT
export REDIS_URL=redis://localhost:6379/$REDIS_DB
export AUTH_MOCK=true
# `db:migrate` in development re-dumps db/schema.rb; keep the old repository's file as it is.
export SCHEMA=${TMPDIR:-/tmp}/${DB}_schema.rb

# postgres and redis of the marketplace dev setup (stopped after a Docker restart)
docker start $DB_CONTAINER marketplace-redis-1 >/dev/null
docker start $ES_CONTAINER >/dev/null 2>&1 ||
  docker run -d --name $ES_CONTAINER -p 127.0.0.1:$ES_PORT:9200 -e discovery.type=single-node \
    -e ES_JAVA_OPTS="-Xms512m -Xmx512m" arm64v8/elasticsearch:7.8.0 >/dev/null
curl -s -o /dev/null --retry 40 --retry-delay 3 --retry-connrefused --retry-all-errors \
  "$ELASTICSEARCH_URL/_cluster/health?wait_for_status=yellow&timeout=60s"

cd $ROOT/$REPO

case $1 in
  "")
    FOREMAN_ENV=${TMPDIR:-/tmp}/${DB}_foreman.env
    : > $FOREMAN_ENV
    exec bin/dev -e $FOREMAN_ENV -p $WEB_PORT
    ;;
  restore)
    [ -f "$2" ] || { echo "no dump file: $2"; exit 1; }
    docker exec $DB_CONTAINER psql -U mp -d postgres -v ON_ERROR_STOP=1 -q \
      -c "DROP DATABASE IF EXISTS $DB" -c "CREATE DATABASE $DB OWNER mp"
    docker exec -i $DB_CONTAINER psql -U mp -d $DB -v ON_ERROR_STOP=1 -q < "$2" >/dev/null
    bundle exec rails db:migrate
    bundle exec rails searchkick:reindex:all
    curl -s "$ELASTICSEARCH_URL/_cat/indices?h=index,docs.count" | sort
    ;;
  *)
    exec "$@"
    ;;
esac
