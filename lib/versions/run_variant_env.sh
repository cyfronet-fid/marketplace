#!/bin/zsh
# Runs the consolidated marketplace codebase as one deployment variant, isolated
# from the marketplace dev environment (mp_development, elasticsearch on 9200,
# redis database 0 are never touched):
#
#   variant      database           elasticsearch (container, port)  redis db  frontend
#   pl           mp_pl_dump         mp-pl-el           9201          5         pl-customization
#   whitelabel   mp_whitelabel_env  mp-whitelabel-el   9202          6         whitelabel-customization
#   marketplace  mp_marketplace_env mp-marketplace-el  9203          7         the repository's own
#
# Databases live in the marketplace-db-1 container (there is no local postgres
# client; everything goes through `docker exec`). The elasticsearch container
# is created on first use. The web port comes from the repository's .env (PORT),
# so only one variant runs at a time.
#
# Usage:
#   run_variant_env.sh <variant>                    start web, sidekiq and the css/js watchers
#   run_variant_env.sh <variant> restore <dump.sql> recreate the database from a plain SQL dump of
#                                                   that deployment, run the migrations, reindex
#   run_variant_env.sh <variant> prime              recreate the database from db/schema.rb with the
#                                                   variant's sample data (dev:prime), reindex
#   run_variant_env.sh <variant> <command...>       any command in the same environment, e.g.
#                                                   run_variant_env.sh pl bundle exec rails c
#
# restore and prime drop the variant's database first; stop the application
# before running them (open connections block the drop).
#
# The customization directories (pl-customization, whitelabel-customization) are
# looked up in the directory that holds this repository; MP_WORKSPACE=<dir>
# points to another one.
set -e
APP=${0:A:h:h:h}
ROOT=${MP_WORKSPACE:-${APP:h}}
DB_CONTAINER=marketplace-db-1

VARIANT=$1
case $VARIANT in
  pl)          DB=mp_pl_dump;         ES_PORT=9201; REDIS_DB=5; CUSTOMIZATION=$ROOT/pl-customization ;;
  whitelabel)  DB=mp_whitelabel_env;  ES_PORT=9202; REDIS_DB=6; CUSTOMIZATION=$ROOT/whitelabel-customization ;;
  marketplace) DB=mp_marketplace_env; ES_PORT=9203; REDIS_DB=7; CUSTOMIZATION= ;;
  *) echo "usage: run_variant_env.sh <pl|whitelabel|marketplace> [restore <dump.sql> | prime | <command...>]"; exit 1 ;;
esac
shift
ES_CONTAINER=mp-$VARIANT-el

export MARKETPLACE_VARIANT=$VARIANT
export DATABASE_URL=postgres://mp:mp@127.0.0.1:5432/$DB
export ELASTICSEARCH_URL=http://127.0.0.1:$ES_PORT
export REDIS_URL=redis://localhost:6379/$REDIS_DB
if [ -n "$CUSTOMIZATION" ]; then
  export CUSTOMIZATION_PATH=$CUSTOMIZATION
else
  unset CUSTOMIZATION_PATH
fi
# `db:migrate` in development re-dumps db/schema.rb from the connected
# database; a deployment's database must not overwrite the repository's file.
export SCHEMA=${TMPDIR:-/tmp}/mp_${VARIANT}_env_schema.rb

start_elasticsearch() {
  docker start $ES_CONTAINER >/dev/null 2>&1 ||
    docker run -d --name $ES_CONTAINER -p 127.0.0.1:$ES_PORT:9200 -e discovery.type=single-node \
      -e ES_JAVA_OPTS="-Xms512m -Xmx512m" arm64v8/elasticsearch:7.8.0 >/dev/null
  curl -s -o /dev/null --retry 40 --retry-delay 3 --retry-connrefused --retry-all-errors \
    "$ELASTICSEARCH_URL/_cluster/health?wait_for_status=yellow&timeout=60s"
}

recreate_database() {
  docker exec $DB_CONTAINER psql -U mp -d postgres -v ON_ERROR_STOP=1 -q \
    -c "DROP DATABASE IF EXISTS $DB" -c "CREATE DATABASE $DB OWNER mp"
}

reindex() {
  bundle exec rails searchkick:reindex:all
  curl -s "$ELASTICSEARCH_URL/_cat/indices?h=index,docs.count" | sort
}

# postgres and redis of the marketplace dev setup (stopped after a Docker restart)
docker start $DB_CONTAINER marketplace-redis-1 >/dev/null
start_elasticsearch
cd $APP

case $1 in
  "")
    exec bin/dev
    ;;
  restore)
    [ -f "$2" ] || { echo "no dump file: $2"; exit 1; }
    recreate_database
    docker exec -i $DB_CONTAINER psql -U mp -d $DB -v ON_ERROR_STOP=1 -q < "$2" >/dev/null
    bundle exec rails db:migrate
    reindex
    ;;
  prime)
    recreate_database
    # dev:prime runs db:setup, which has to read the repository's schema. The
    # sample data's callbacks update the search indices, so they have to exist
    # (empty) before it runs.
    SCHEMA=db/schema.rb bundle exec rails db:schema:load
    bundle exec rails searchkick:reindex:all
    SCHEMA=db/schema.rb bundle exec rails dev:prime
    reindex
    ;;
  *)
    exec "$@"
    ;;
esac
