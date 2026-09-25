#!/bin/zsh
# Usage: assemble_customization.sh <old-repo-name> <target-dir>
# Copies the files of <old-repo> that differ from marketplace (or exist only
# there) into the CUSTOMIZATION_PATH layout under <target-dir>.
# <old-repo-name> is looked up in the directory that holds this repository;
# MP_WORKSPACE=<dir> points to another one. <target-dir> is relative to the
# current directory.
set -e
APP=${0:A:h:h:h}
ROOT=${MP_WORKSPACE:-${APP:h}}
REPO=$1
TARGET=$2
BASE=$APP

# Old-repo files left out of the customization. They differ from marketplace
# because the old repo's Ruby code differs, not the deployment's look, and
# they raise on the consolidated code:
#   nav/_category, nav/_categories  call `.permit!` on category_query_params,
#     a plain hash here (ActionController::Parameters in the old repos)
#   sidebar_component/_array (pl)   predates providers.public_contact_emails
#     (strings) and calls `.email` on every element
#   backoffice/providers show, _show, tabs/_profile (whitelabel)   list the
#     provider's services, but the wrapper between them stopped passing
#     `services`/`pagy` in the old repo (e0687092), so the page raises there
#     too; nothing else uses them, whitelabel gets marketplace's provider page
EXCLUDED=(
  app/views/backoffice/other_settings/categories/nav/_category.html.haml
  app/views/services/nav/_category.html.haml
  app/views/services/nav/_categories.html.haml
)
if [ "$REPO" = pl-marketplace ]; then
  EXCLUDED+=(app/views/components/presentable/sidebar_component/_array.html.haml)
fi
if [ "$REPO" = whitelabel-marketplace ]; then
  EXCLUDED+=(
    app/views/backoffice/providers/show.html.haml
    app/views/backoffice/providers/_show.html.haml
    app/views/backoffice/providers/tabs/_profile.html.haml
  )
fi

# Prints the paths (relative to $1's copy of $3) that differ or exist only in $REPO.
# `diff -rq` names a directory that exists only in $REPO once, as a directory;
# it is expanded to its files so that every entry is a file (rsync
# --files-from does not recurse, and EXCLUDED lists files).
differing() {
  local sub=$1 entry file
  diff -rq "$BASE/$sub" "$ROOT/$REPO/$sub" 2>/dev/null | awk -v repo="$ROOT/$REPO/$sub/" '
    /^Files/ { print $4 }
    /^Only in/ && index($0, "Only in " repo) == 1 { dir=$3; sub(/:$/, "", dir); print dir "/" $4 }
    /^Only in/ && $3 == substr(repo, 1, length(repo) - 1) ":" { print substr(repo, 1, length(repo) - 1) "/" $4 }
  ' | sed "s|^$ROOT/$REPO/$sub/||" | sort -u | while read -r entry; do
    if [ -d "$ROOT/$REPO/$sub/$entry" ]; then
      find "$ROOT/$REPO/$sub/$entry" -type f | sed "s|^$ROOT/$REPO/$sub/||"
    else
      echo "$entry"
    fi
  done | sort -u | while read -r file; do
    (( ${EXCLUDED[(Ie)$sub/$file]} )) || echo "$file"
  done
}

copy_area() {
  local sub=$1 dest=$2
  local list
  list=$(differing "$sub")
  if [ -n "$list" ]; then
    mkdir -p "$TARGET/$dest"
    echo "$list" | rsync -a --files-from=- "$ROOT/$REPO/$sub/" "$TARGET/$dest/"
  fi
  echo "$dest: $(echo "$list" | grep -c .) entries"
}

rm -rf "$TARGET"
mkdir -p "$TARGET/locale"
copy_area app/views views
copy_area config/locales config/locales
copy_area app/assets/images images
copy_area app/assets/stylesheets stylesheets

mkdir -p "$TARGET/javascript/app" "$TARGET/javascript/controllers"
for f in app/cookies_policy.js controllers/exit_controller.js controllers/form_controller.js application.js controllers/form_redirect_controller.js; do
  if [ -f "$ROOT/$REPO/app/javascript/$f" ] && ! diff -q "$BASE/app/javascript/$f" "$ROOT/$REPO/app/javascript/$f" >/dev/null 2>&1; then
    cp "$ROOT/$REPO/app/javascript/$f" "$TARGET/javascript/$f"
    echo "javascript/$f"
  fi
done
echo "done: $TARGET"
