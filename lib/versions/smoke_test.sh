#!/bin/zsh
# Smoke test of a locally running marketplace (any variant): requests the main
# public, backoffice and admin pages with GET and prints the status of each.
# Nothing is submitted, so apart from the login no data changes.
#
# Usage:
#   smoke_test.sh [base-url]        default http://localhost:5000
#
#   run_variant_env.sh <variant>    # in another terminal: start the application
#   smoke_test.sh
#   rake "smoke:crawl[http://localhost:5000,${TMPDIR:-/tmp}/mp_smoke_cookies_5000.txt]"
#                                   # optional: follow every link with the same session
#
# Login: development has no password form; the auth mock (AUTH_MOCK=true in
# .env) logs in through GET /users/login and creates the user on every call.
# Under pl an email can be used once only (unique emails), so every login here
# uses a new smoke.<timestamp>@example.org with the admin, coordinator and
# executive roles. The session is kept in $JAR and reused while it is valid,
# so repeated runs do not add users. Delete $JAR to force a new login.
#
# The service and provider pages are taken from the first link on the
# listings, the provider tabs from the links of the backoffice provider page
# (requested as turbo streams, the way the tabs request them).
#
# Exit status is 1 when any page answers 4xx/5xx. The exception and backtrace
# of a 500 are in log/development.log of the application.
BASE=${1:-http://localhost:5000}
# One session file per port, so the old and the consolidated application can be tested side by side.
JAR=${TMPDIR:-/tmp}/mp_smoke_cookies_${${BASE##*:}%%/*}.txt
FAILED=0

code() {
  curl -s -o /dev/null -w "%{http_code}" -H "Accept: ${2:-text/html}" -b "$JAR" "$BASE$1"
}

check() {
  local http_status
  http_status=$(code "$1" "$2")
  echo "$http_status $1${2:+  ($2)}"
  [ "$http_status" -ge 400 ] && FAILED=$((FAILED + 1))
  return 0
}

# $2/<id> of the first href on page $1 that starts with it; "new" and "c"
# (category listings) are not ids.
first_link() {
  curl -s -H "Accept: text/html" -b "$JAR" "$BASE$1" | grep -o "href=\"$2/[^\"/?#]*" | sed 's/^href="//' |
    grep -v "^$2/\(new\|c\)\$" | head -1
}

if [ "$(code /)" = 000 ]; then
  echo "no application at $BASE"
  exit 1
fi

if [ "$(code /profile)" != 200 ]; then
  EMAIL="smoke.$(date +%s)@example.org"
  curl -s -o /dev/null -c "$JAR" -G "$BASE/users/login" \
    --data-urlencode "email=$EMAIL" --data-urlencode "password=irrelevant" \
    --data-urlencode "first_name=Smoke" --data-urlencode "last_name=Test" \
    --data-urlencode "roles[]=admin" --data-urlencode "roles[]=coordinator" --data-urlencode "roles[]=executive"
  if [ "$(code /profile)" != 200 ]; then
    echo "login through the auth mock failed (is AUTH_MOCK=true set?)"
    exit 1
  fi
  echo "logged in as $EMAIL"
fi

SERVICE=$(first_link /services /services)
PROVIDER=$(first_link /providers /providers)
BO_SERVICE=$(first_link /backoffice/services /backoffice/services)
BO_PROVIDER=$(first_link /backoffice/providers /backoffice/providers)

for page in / /services "/services?q=data" $SERVICE ${SERVICE:+$SERVICE/details} ${SERVICE:+$SERVICE/offers} \
  /providers $PROVIDER /catalogues /about /communities /target_users /projects /profile \
  /backoffice/services /backoffice/services/new $BO_SERVICE ${BO_SERVICE:+$BO_SERVICE/edit} \
  /backoffice/providers $BO_PROVIDER /backoffice/catalogues /backoffice/other_settings/scientific_domains \
  /backoffice/other_settings/categories /backoffice/statistics /admin; do
  check "$page"
done

if [ -n "$BO_PROVIDER" ]; then
  curl -s -H "Accept: text/html" -b "$JAR" "$BASE$BO_PROVIDER" | grep -o 'href="[^"]*[?&]tab=[^"]*"' |
    sed 's/^href="//; s/"$//; s/&amp;/\&/g' | sort -u | while read -r tab; do
    check "$tab" text/vnd.turbo-stream.html
  done
fi

[ -z "$SERVICE" ] && echo "no service link found on /services"
[ -z "$BO_PROVIDER" ] && echo "no provider link found on /backoffice/providers"
echo "failed: $FAILED"
[ "$FAILED" -eq 0 ]
