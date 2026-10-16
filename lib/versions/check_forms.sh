#!/bin/zsh
# Checks the backoffice forms of a locally running marketplace (any variant):
# logs in through the auth mock, then renders every backoffice form and
# submits the edit forms back with their own values (rake "smoke:forms[...]",
# see lib/tasks/smoke.rake for what is submitted and what is never touched).
#
# Usage:
#   check_forms.sh [base-url]        default http://localhost:5000
#
#   run_variant_env.sh pl            # in another terminal: start the application as pl
#   check_forms.sh                   # render and re-submit the edit forms
#   SUBMIT=all check_forms.sh        # also submit the /new forms empty (expects 422)
#   SUBMIT=none check_forms.sh       # only render the form pages
#   SAMPLE=3 check_forms.sh          # three records per resource instead of two
#
# A deployment has no auth mock: log in there in a browser as a coordinator,
# copy the value of its _mp_session cookie (developer tools, Application,
# Cookies) and pass it:
#
#   MP_SESSION=<cookie value> check_forms.sh https://marketplace-16.docker-fid.grid.cyf-kr.edu.pl
#
# A re-saved record gets a new updated_at and runs its callbacks, so run this
# against a local variant environment or accept that on a test deployment.
#
# Exit status is 1 when a form page or a submission failed. The exception and
# backtrace of a 500 are in log/development.log of the application (in
# production the page shows no message; see the logs of the deployment).
BASE=${1:-http://localhost:5000}
# One session file per host and port, shared with smoke_test.sh.
JAR=${TMPDIR:-/tmp}/mp_smoke_cookies_${${${BASE#*://}%%/*}//:/_}.txt
APP=${0:A:h:h:h}

source "${0:A:h}/smoke_login.sh"

if [ "$(smoke_status "$BASE" "$JAR" /)" = 000 ]; then
  echo "no application at $BASE"
  exit 1
fi
if [ -n "$MP_SESSION" ]; then
  # A cookie jar in the Netscape format of curl: domain, subdomains, path, secure, expiry, name, value.
  HOST=${${BASE#*://}%%[:/]*}
  printf '#HttpOnly_%s\tFALSE\t/\tTRUE\t0\t_mp_session\t%s\n' "$HOST" "$MP_SESSION" > "$JAR"
  if [ "$(smoke_status "$BASE" "$JAR" /profile)" != 200 ]; then
    echo "the session of MP_SESSION is not logged in at $BASE"
    exit 1
  fi
else
  smoke_login "$BASE" "$JAR" || exit 1
fi

cd "$APP" && exec bundle exec rake "smoke:forms[$BASE,$JAR]"
