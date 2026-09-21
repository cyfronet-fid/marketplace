# Customizing marketplace

One codebase serves several deployments. A deployment is shaped by three
independent things:

| What differs | Mechanism | Where it lives |
| --- | --- | --- |
| Look: pages, texts, styles, scripts, images | `CUSTOMIZATION_PATH` | a directory outside this repository |
| Behaviour: routes, validations, flows, data model | `MARKETPLACE_VARIANT` | this repository, behind `Mp::Variant` |
| Settings: URLs, feature flags, credentials | environment variables | the deployment's environment |

This document covers the first in detail and says when to reach for the other
two. Behaviour per variant is tracked in
[deployment_variants.md](deployment_variants.md); the environment variables are
listed in the [README](../README.md#environmental-variables).

## The customization directory

`CUSTOMIZATION_PATH` points to a directory with this layout. Every part
mirrors a directory of the repository, and a file in it replaces the
repository's file with the same relative path. Everything that is not
overridden keeps coming from the repository.

```text
$CUSTOMIZATION_PATH
├── views/            over app/views
├── config/locales/   added to config/locales
├── locale/           instead of locale/ (gettext); must exist, may be empty
├── javascript/       over app/javascript
├── stylesheets/      over app/assets/stylesheets
└── images/           over app/assets/images
```

Only `locale/` is required: gettext raises at boot
(`path .../locale could not be found!`) when it is missing. The other
directories are optional.

| Part | Wired in | Read when | After adding a file |
| --- | --- | --- | --- |
| `views/` | `config/application.rb` | every request in development, boot in production | nothing in development |
| `config/locales/` | `config/application.rb` | boot (file list), change of a listed file in development | restart |
| `locale/` | `config/initializers/fast_gettext.rb` | boot | restart |
| `javascript/` | `config/esbuild.config.js` | build (`yarn build`) | rebuild, or restart `bin/dev` |
| `stylesheets/` | `config/sass.config.js` | build (`yarn build:css`); the watcher follows both directories | nothing under `bin/dev` |
| `images/` | `config/initializers/assets.rb` | boot (file list) | restart |

### Views

`$CUSTOMIZATION_PATH/views` is put in front of `app/views`, so lookup is per
file: `views/layouts/_navbar.html.haml` replaces only the navbar partial,
`views/services/show.html.haml` only that page. Layouts and mailer views are
under `app/views` as well and are overridden the same way. A view that exists
only in the customization directory is found too, which matters when the
repository renders a partial by a computed name (for example a provider tab).

Limits:

- ViewComponent templates next to their class (`app/components/**/*.haml`) are
  not looked up through the view path and cannot be overridden from the
  customization directory. Partials that a component renders from
  `app/views/components/` can. A component template that has to differ per
  variant lives in the repository as `<name>.html+pl.haml` or
  `<name>.html+whitelabel.haml`: `ApplicationController#set_variant` sets
  `request.variant` from `Mp::Variant` outside `marketplace`, and both Action
  View and ViewComponent prefer the matching template.
- An overriding view runs against this repository's helpers, routes, policies
  and the locals its caller passes. When the repository changes any of those,
  the override keeps its old calls and raises (`undefined local variable or
  method`, `undefined method ... for nil`, a missing route helper). Override
  the smallest partial that holds the difference, not the page around it, and
  rediff the overrides against the repository on every upgrade.

### Texts

- `config/locales/**/*.{rb,yml}` is loaded after the repository's locale files.
  A key defined there wins; all other keys fall back to the repository's. A
  file needs only the keys that differ.
- `locale/` holds the gettext catalogue (`locale/en/marketplace.po`) for
  strings written as `_("...")`. It replaces the repository's `locale/`
  directory, it is not merged with it. `rake gettext:find` also scans the
  customization directory.

### JavaScript

`yarn build` bundles `app/javascript/application.js`. With
`CUSTOMIZATION_PATH` set, every relative import is resolved against
`$CUSTOMIZATION_PATH/javascript` first and `app/javascript` second, whether the
importing file is customized or not:

- `javascript/controllers/form_controller.js` replaces that Stimulus
  controller everywhere.
- `javascript/application.js` replaces the entry point.
- A new Stimulus controller has to be registered: copy
  `app/javascript/controllers/index.js` into the customization directory and
  add the `import` and `application.register` lines there.
- Packages come from the repository's `node_modules`; a customization cannot
  add a dependency of its own.

### Stylesheets

`yarn build:css` compiles `app/assets/stylesheets/application.scss` with the
same rule: an `@import` or `@use` of a relative path is looked up in
`$CUSTOMIZATION_PATH/stylesheets` first. Overriding `_variables.scss` and
`_bootstrap-customizations.scss` is enough for colours and typography;
`application.scss` itself can be replaced too. Bare imports resolve from
`node_modules`.

### Images

`$CUSTOMIZATION_PATH/images` is put in front of the asset paths and all its
files are precompiled. `image_tag "logo.svg"` and `url("logo.svg")` in a
stylesheet then serve the customized file. New file names work as well, for
views in the customization directory that reference them.

### Compared with the former repositories

In `marketplace` before the consolidation, `pl-marketplace` and
`whitelabel-marketplace` the mechanism is identical and covers `views/`,
`config/locales/` and `locale/` only. Their README also names JavaScript and
SCSS, but that part was written for webpack and has been commented out since
the move to esbuild and the sass command line, so each fork kept its own
stylesheets, scripts and images in `app/`. `javascript/`, `stylesheets/`,
`images/` and the per-variant component templates were added with the
consolidation; views, locales and gettext work as before.

## Running with a customization

Development:

```shell
export MARKETPLACE_VARIANT=whitelabel        # behaviour, see below
export CUSTOMIZATION_PATH=/path/to/customization
bin/dev                                      # web, sidekiq, css and js watchers
```

`bin/dev` starts foreman, and foreman lets a key in `.env` win over an exported
variable. Keep `CUSTOMIZATION_PATH` and `MARKETPLACE_VARIANT` out of `.env`
when switching between deployments, or start with another env file
(`bin/dev -e path/to/file`).

Production: the directory has to be present and `CUSTOMIZATION_PATH` set both
when the assets are built and when the application runs.
`rake assets:precompile` runs `yarn build` and `yarn build:css` and
fingerprints the images, so JavaScript, stylesheets and images are fixed at
build time; views and texts are read at boot. The `Dockerfile` builds the
assets without a customization, so a deployment image has to add the directory
and the variable before its `assets:precompile` step.

## When a customization is not enough

A view can only show what the Ruby code provides. When a deployment needs a
route, an action, a permitted parameter, an association or a validation the
repository does not have, add it to the repository behind the variant:

```ruby
post :exit unless Mp::Variant.marketplace?
```

- `MARKETPLACE_VARIANT` is `marketplace`, `pl` or `whitelabel`
  (`config/variants.yml`); production refuses to boot without it. Predicates:
  `Mp::Variant.marketplace?`, `.pl?`, `.whitelabel?`.
- Keep the condition inline where the behaviour differs. If two deployments
  only look different in code but do the same thing, unify instead of gating.
- CI runs the whole suite as `marketplace` and the request, lib, helper and
  routing specs again as `pl` and as `whitelabel`. Examples tagged
  `variant: :marketplace` are skipped in those two runs; tag marketplace-only
  behaviour that way and stub the `Mp::Variant` predicates to cover the other
  branch.
- A new deployment that needs behaviour of its own gets a new entry in
  `config/variants.yml` and its predicate in `lib/mp/variant.rb`. A deployment
  that differs only in look and settings reuses an existing variant.

Prefer an environment variable over a variant condition for a value or a
switch (`ENABLE_COMMONS`, `SHOW_RECOMMENDATION_PANEL`,
`HOME_PAGE_EXTERNAL_LINKS_ENABLED`, `MP_ENABLE_EXTERNAL_SEARCH`,
`MP_META_TITLE`, `PORTAL_BASE_URL`, ...): it needs no code change for the next
deployment.

## Preparing a frontend for a deployment

1. Pick the variant whose behaviour the deployment has.
2. Create the directory with an empty `locale/`.
3. Start with branding that needs no views: `stylesheets/_variables.scss`,
   `images/` (logo, favicon), `config/locales/` for texts.
4. Override views only where markup has to differ, smallest partial first.
5. Run it and go through the pages as every role. In development the login
   can be mocked: set `AUTH_MOCK=true` and open
   `/users/login?email=me@example.org&roles[]=admin&roles[]=coordinator&roles[]=executive`.
   Public pages, the order flow, `/backoffice`, `/admin` and the provider and
   service tabs (they load as turbo streams) all render customized views.
6. For every page that fails, the trace names the file. If it is inside the
   customization directory:
   - the view differs from the repository's only in the failing call: delete
     the override, the repository's view is used;
   - the view shows something the deployment really has: port the missing
     piece into the repository behind `Mp::Variant` (previous section) and keep
     the override.
7. Build the production assets with the directory in place and check that the
   stylesheet, the scripts and the images are the customized ones.

## Troubleshooting

| Symptom | Cause |
| --- | --- |
| Boot fails with `path .../locale could not be found!` | `$CUSTOMIZATION_PATH/locale` is missing; create it empty |
| An override is ignored | wrong relative path (it has to match the repository's path below `app/views`, `app/javascript`, `app/assets/stylesheets` or `app/assets/images`), or a restart or rebuild is due (table above) |
| `undefined local variable or method` in a customized view | the override was written for other Ruby code; its caller passes different locals or the helper is gone |
| `No route matches` or an undefined `*_path` helper from a customized view | the route exists in another variant or not at all; see "When a customization is not enough" |
| Styles or scripts unchanged in production | `CUSTOMIZATION_PATH` was not set when `assets:precompile` ran |
| A customized image is missing in production | the file was added after the assets were built |
| A new Stimulus controller does nothing | it is not registered in a customized `controllers/index.js` |
