# Login of the smoke scripts, sourced by smoke_test.sh and check_forms.sh.
#
#   smoke_login <base-url> <cookie-jar>
#
# Development has no password form; the auth mock (AUTH_MOCK=true in .env)
# logs in through GET /users/login and creates the user on every call. Under
# pl an email can be used once only (unique emails), so every login uses a
# new smoke.<timestamp>@example.org with the admin, coordinator and executive
# roles. The session is kept in the cookie jar and reused while it is valid,
# so repeated runs do not add users. Delete the jar to force a new login.
# Returns 1 when the login fails.
smoke_login() {
  local base=$1 jar=$2 email
  [ "$(smoke_status "$base" "$jar" /profile)" = 200 ] && return 0

  email="smoke.$(date +%s)@example.org"
  curl -s -o /dev/null -c "$jar" -G "$base/users/login" \
    --data-urlencode "email=$email" --data-urlencode "password=irrelevant" \
    --data-urlencode "first_name=Smoke" --data-urlencode "last_name=Test" \
    --data-urlencode "roles[]=admin" --data-urlencode "roles[]=coordinator" --data-urlencode "roles[]=executive"
  if [ "$(smoke_status "$base" "$jar" /profile)" != 200 ]; then
    echo "login through the auth mock failed (is AUTH_MOCK=true set?)"
    return 1
  fi
  echo "logged in as $email"
}

# The HTTP status of GET <base-url><path> with the session of the jar.
smoke_status() {
  curl -s -o /dev/null -w "%{http_code}" -H "Accept: text/html" -b "$2" "$1$3"
}
