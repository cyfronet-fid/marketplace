# Ticket: build the breadcrumb trail in the controllers

## Context

Breadcrumbs come from the `gretel` gem. The setup has three parts:

- `config/breadcrumbs/*.rb` holds about 80 crumb definitions. Each `crumb`
  block computes the link of one level and names its `parent`.
- 80 views declare the crumb of their page with one line, for example
  `- breadcrumb :service, @service`.
- `app/views/layouts/_breadcrumb.html.haml` and
  `app/views/layouts/backoffice/_navbar.html.haml` call the `breadcrumbs`
  helper, which walks the parent chain to the root.

The trail of one page is thus spread over the view, the crumb block and the
blocks of all ancestors. Some parents depend on request state (`params[:from]`,
`params[:fromc]`, `session[:query]`), so request logic lives in configuration
files.

Current state, the start point of this ticket:

- One definition per crumb. Parents are explicit (`case params[:from]`).
- `$CUSTOMIZATION_PATH/config/breadcrumbs/**/*.rb` is loaded after the
  repository's files (`config/initializers/breadcrumbs.rb`). A crumb defined
  there replaces the repository's crumb with the same name. The pl frontend
  keeps its own trail this way, see `docs/customization.md`.

## Goal

Each controller adds its own level of the trail. The layout renders the
collected trail. The `gretel` gem, `config/breadcrumbs/` and the view
declarations go away.

## Not in scope

- A change of the rendered markup, the separator or the labels.
- New breadcrumbs on pages that show none today.

## Design

1. A concern on `ApplicationController`:

   ```ruby
   module Breadcrumbs
     extend ActiveSupport::Concern
     included { helper_method :breadcrumbs }

     def breadcrumbs = @breadcrumbs ||= []
     def add_breadcrumb(label, path = nil) = breadcrumbs << [label, path]
   end
   ```

2. One root per area, as a `before_action`:
   - `ApplicationController`: "Home", `root_path`.
   - `Backoffice::ApplicationController`: "Backoffice", `backoffice_path`.
   - `Admin::ApplicationController`: "Admin", `admin_path`.
3. One collection level per resource controller, for example
   `Backoffice::ServicesController` adds "Services" with
   `backoffice_services_path`. The list of controllers is the list of view
   directories that declare a crumb today (39 directories).
4. One record level in each nested controller, added after the record is
   loaded. The callback has to run after the `find_*` callback of the
   controller.
5. One leaf per action: `show` adds the record name, `new` and `edit` add
   their label. 23 controllers render `:new` or `:edit` again after a failed
   save, so the leaf is a callback, not a line in the action:

   ```ruby
   before_action -> { add_breadcrumb "New" }, only: %i[new create]
   before_action -> { add_breadcrumb "Edit" }, only: %i[edit update]
   ```

6. The two layout partials render `breadcrumbs` as links with the markup
   `gretel` produces today (`.breadcrumbs` container, `›` separator,
   `data-probe` on the links), so the stylesheets and the crawler stay valid.
7. The crumbs that read `params[:from]` (service details and opinions, the
   ordering configuration) become a `case params[:from]` in their controllers
   with the same branches as today.

## Variants

- The pl trail differs at the top: "All collections" instead of "Home", and
  the services, data sources, providers and catalogues lists under it, with
  external search URLs when `MP_ENABLE_EXTERNAL_SEARCH` is on. This is an
  inline `Mp::Variant.pl?` in the root callback of `ApplicationController`
  and in the three list controllers.
- pl shows a trail on pages that have none on marketplace: help, about,
  communities, target users, profiles, favourites, new and edited projects.
  Decide per page if the trail shows on every variant or only under pl.

## Customization directories

`customization/pl/views` and `customization/whitelabel/views` carry the
`- breadcrumb` declarations of the old repositories (24 and 21 files). The old
repositories keep `gretel`, so every rebuild of the directories brings the
lines back. Choose one:

- A `breadcrumb` view helper that maps the old declaration onto the new
  trail (a shim; the view declaration stays an API).
- A strip step in `lib/versions/assemble_customization.sh` that removes the
  lines from the copied views.
- Do this ticket after the old repositories are frozen.

Also remove `copy_area config/breadcrumbs` from the assemble script and the
`config/breadcrumbs` directories of the customizations.

## Steps

1. Write request specs for the trails that exist today. No spec asserts a
   breadcrumb at the moment. Cover one page per area under marketplace and
   pl: a public service page with a category parent, a nested backoffice
   form (`new` and a failed `create`), an admin page, a service tab opened
   with `from=backoffice_service`.
2. Add the concern and the layout rendering next to `gretel`, both active,
   and compare the output page by page with `rake smoke:crawl`.
3. Move the levels controller by controller. Remove the declaration from each
   moved view in the same change.
4. Remove the gem, `config/breadcrumbs/`, `config/initializers/breadcrumbs.rb`
   and the breadcrumb sections of `docs/customization.md` and
   `docs/deployment_variants.md`.
5. Crawl marketplace, pl and whitelabel and compare the trails with the
   crawl before the change.

## Acceptance

- No `breadcrumb :` declaration under `app/views`. No `config/breadcrumbs/`.
  `gretel` is not in the `Gemfile`.
- The specs of step 1 pass unchanged.
- The crawl of each variant renders without `undefined method breadcrumb`.

## Size

39 controllers gain one to four lines. 80 views lose one line. Two layout
partials change. About 440 lines of configuration go away. The two places
where the change can go wrong are the `create` and `update` pairs and the
order of the callbacks relative to the record loading.
