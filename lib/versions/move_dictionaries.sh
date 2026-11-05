#!/bin/zsh
# Extracts the backoffice dictionaries from a plain SQL dump of a pl or
# whitelabel deployment. The output is one SQL file. The file loads the
# dictionary tables into an instance that was deployed with an empty database:
#
#   categories, platforms, scientific_domains, target_users, vocabularies
#
# The vocabularies table holds all backoffice vocabulary types. The offer
# category select reads the Vocabulary::ServiceCategory rows from it.
#
# The generated file is safe to apply more than one time: it stops with an
# error if a dictionary table is not empty, and it changes nothing then. After
# the load it sets each id sequence to the highest loaded id.
#
# Usage:
#   move_dictionaries.sh <dump.sql> [output.sql]
#
# The default output is ${TMPDIR:-/tmp}/dictionaries.sql. Load the output on
# the instance's database host, for example:
#
#   docker compose exec -T db psql -U mp -d <database> -v ON_ERROR_STOP=1 \
#     -1 < dictionaries.sql
set -e

DUMP=$1
OUT=${2:-${TMPDIR:-/tmp}/dictionaries.sql}
TABLES=(categories platforms scientific_domains target_users vocabularies)

[ -f "$DUMP" ] || { echo "usage: move_dictionaries.sh <dump.sql> [output.sql]"; exit 1; }

{
  echo "-- Backoffice dictionaries, extracted from a deployment dump by"
  echo "-- lib/versions/move_dictionaries.sh. Apply with psql -v ON_ERROR_STOP=1."
  echo "BEGIN;"
  echo
  echo "-- Stop if a dictionary table already has rows."
  echo "DO \$\$"
  echo "BEGIN"
  for t in $TABLES; do
    echo "  PERFORM 1 FROM public.$t LIMIT 1;"
    echo "  IF FOUND THEN RAISE EXCEPTION '$t is not empty, not loading dictionaries'; END IF;"
  done
  echo "END \$\$;"
  echo

  for t in $TABLES; do
    awk -v t="$t" '
      $0 ~ "^COPY public\\."t" " { in_block = 1 }
      in_block { print }
      in_block && /^\\\.$/ { in_block = 0; print "" }
    ' "$DUMP"
  done

  echo "-- Continue each id sequence after the highest loaded id."
  for t in $TABLES; do
    echo "SELECT setval(pg_get_serial_sequence('public.$t', 'id'), (SELECT COALESCE(MAX(id), 1) FROM public.$t));"
  done
  echo "COMMIT;"
} > "$OUT"

for t in $TABLES; do
  rows=$(awk -v t="$t" '
    $0 ~ "^COPY public\\."t" " { in_block = 1; next }
    in_block && /^\\\.$/ { in_block = 0 }
    in_block { n++ }
    END { print n + 0 }
  ' "$OUT")
  echo "$t: $rows rows"
done
echo "wrote $OUT"
