# Repository consolidation status

`marketplace`, `pl-marketplace` and `whitelabel-marketplace` are being merged
into this repository on `feat/whitelabel-integration`. One codebase serves
three deployments, selected at boot by `MARKETPLACE_VARIANT`
(`marketplace` / `pl` / `whitelabel`), each with its own database and secrets.

Rules used so far:

- Behavior that really differs between the repos is gated with
  `Mp::Variant`. Code that only looked different, or a plain bug in one repo,
  is unified or fixed for every variant.
- Every variant ends with the same database schema. PL-only tables exist
  everywhere but are only used under `Mp::Variant.pl?`.
- Applied migrations are never edited. Repairs are new forward migrations;
  migrations that would delete PL data get a `pl?` guard.
- A migration ported from another repo keeps its original version, so
  databases that already ran it skip it.

## Done

Variant mechanism and configuration:

- `Mp::Variant`, `config/variants.yml`, rejection of unknown variants; the
  old `whitelabel` config flag folded into `Mp::Variant.whitelabel?`.
- `MARKETPLACE_VARIANT` is required in production: boot raises without it.
- Missing `monitoring_data` credentials return `nil`.
- JMS user-action publishing respects `MP_STOMP_PUBLISHER_ENABLED`.
- Whitelabel client-credentials import token (`Importers::ClientCredentialsToken`,
  `import:authorize`); `deployable_services` is imported only for marketplace.

Controllers and APIs:

- ESS `deployable_services` API is marketplace-only.
- Simple services API serves contacts and countries only for `pl`.
- Provider/organisation name links to the provider page for `pl`/`whitelabel`.
- Save-as-draft for providers is whitelabel-only, also on the server side.
- Small fixes: user API error message, `DataAdministrator` counter guard.
- Marketplace's federation delete renamed to `Service::PcDelete`.

PL data and search:

- `service_pl_profiles` / `provider_pl_profiles` with backfill; legacy PL
  columns removed from `services` / `providers`.
- Profiles are built and autosaved for new PL records; country fields are
  converted like in pl-marketplace.
- Research activities, target users and platforms restored on `Service`.
- PL search fields (tagline, geography, research activities, platforms,
  target users) and PL filter set; other variants keep their index shape.

Database:

- V6 strip migrations guarded against destroying PL data.
- `RestorePlOnlyTables`: recreates the five PL-only tables on non-PL
  databases (verified on a throwaway database).
- Provider `pid` is required and unique, generated when blank, including on
  `save(validate: false)` (ported from pl-marketplace).
- `RenameProjectNameToProjectOwner` (20250518120000, marketplace's version)
  skips when `projects.project_name` is already gone: pl and whitelabel ran
  the same rename as 20250510072744, so their databases see this one as
  pending. Same repair pattern as the guarded V6 strip migrations.
- `RestoreServiceOwnerTables`: recreates `service_user_relationships` and
  `users.owned_services_count` on pl databases (pl dropped service owners in
  2024; `User#service_owner?`, `Service#owned_by?` and the backoffice service
  and bundle policies read them on every variant).
- Verified against the pl-marketplace testing dump of 2026-08-24 (269
  applied versions) restored into a throwaway database: every migration runs
  under `MARKETPLACE_VARIANT=pl`, nothing stays pending, every service and
  provider gets its profile row with the legacy data, 40 blank provider pids
  are backfilled, and the app boots and reads the profiles. After migrating,
  the only differences from `db/schema.rb` are `offer_links` (no repo
  references it) and the testing database's empty `orders` and
  `order_changes` tables, which pl's own schema does not have either.

Lifecycle and messaging:

- Delete, suspend and unpublish are selected per variant through
  `VariantOperation`: marketplace keeps its `Standalone` behavior; pl and
  whitelabel use `Cascading` implementations that enqueue `DeleteJob`,
  `SuspendJob` or `UnpublishJob` for dependent records and save without
  validation. Controllers remove services, offers and bundles through
  `Service/Offer/Bundle::Removal`.
- `Datasource::Delete` renamed to `Datasource::PcDelete`, so `DeleteJob`
  resolves a datasource to `Service::Delete`.
- `Provider#managed_services` ported; registry provider deletes cascade on
  pl/whitelabel (their own `Provider::PcDelete` never defined `call`).
- JMS messages with `resource` as a JSON string are accepted; the subscriber
  and `Jms::ManageMessageJob` now call `Jms::ManageMessage` with its actual
  arguments.
- `Service::Publish` uses the pl/whitelabel ordering on every variant: the
  single offer is published, bundled offers notified and subscribers mailed
  only after the service update succeeds; a failed update returns `false`.

Variant-only features:

- Public `deployable_services` pages, the ordering wizard reused for them and
  `Projects::Services::InfrastructuresController` are routed only for
  marketplace. `Jms::ManageMessage` treats `deployable_application` messages
  as an unknown type on the other variants, as their own subscribers do; the
  `DeployableService::*` jobs and services are unreachable there.
  `Ams::ProcessMessage` is deliberately left ungated.
- PL login identities: `UserIdentity`, `Users::Authenticate` and the
  `user_identities` table exist on every variant (pl's migration keeps its
  version but not its `remove_column :users, :uid`; `AddNullableUidToUsers`
  gives every variant a nullable `users.uid`). Only pl logs in through
  `Users::Authenticate`, reads `User#uid` from the primary identity, validates
  case-insensitive email uniqueness and resolves the users API and the
  `lib/ordering_api` admins through identities; marketplace and whitelabel
  keep `User::Checkin` and `users.uid`. The Check-in token is stored in the
  session only on marketplace (only its `Services::ApplicationController`
  reads it). pl's unique `lower(email)` index was not ported: marketplace
  allows duplicate emails.
- Code files only the other repos had:
  `Backoffice::Vocabulary::ResearchActivityPolicy` and
  `Recommender::Vocabulary::ResearchActivitySerializer` ported
  (`RecommenderLib::SerializeDb` dumps `research_activities` under pl and
  whitelabel, `research_steps` under marketplace); pl's `dialog` Stimulus
  controller added to the bundle for the provider approval and profile
  completion modals; whitelabel's `Provider::CreateAsDraft` is
  `Provider::Draft` here, which now also reindexes (whitelabel's
  `ProvidersController#create` draft branch was not ported: `new` redirects
  to the wizard, so nothing posts it); `Catalogue::PcDelete` has no caller in
  any repo and `Provider::PcDelete` is covered by `Provider::Delete`.

ESS and ordering API:

- `Propagable#propagate_to_ess` and `Ess::Add` take pl's `propagate_offers:`
  option (default unchanged). Under pl, datasources are sent to ESS with the
  datasource profile and `Offer::Create` pushes the service to ESS after
  saving the offer; the other variants keep sending datasources as services
  and only reindex.
- pl's users API rule (`Api::V1::UserPolicy#show?` requires every role), the
  SOMBO admin holding every role and `AddProviderOMS` underscoring the OMS
  name are gated to pl.
- `OrderingApi::AuthorizationTestSetup` creates the sample services with a
  tagline and a geographical availability under pl and whitelabel (order
  type and categories stay: `services.order_type` is `NOT NULL`). The task
  also needed the provider fields and offer category the current models
  require; it failed on every repo without them. A spec runs it under all
  three variants.
- PL Catalogue API ported: `Api::V1::Catalogue::ServicesController`, its
  policy, `Catalogue::ServiceSerializer` (+ alternative identifiers), the
  swagger document and `Service#access_modes` / `Service#logo_url` it reads;
  the route exists only under pl.
- Whitelabel's `Api::V1::Search` differs from marketplace only cosmetically
  (nothing to port). `Federation::ServicesController#map_results` takes
  whitelabel's fallbacks to the nested `result.service` fields for every
  variant, written with `dig` so they stay inert on marketplace responses.
  The federation views still differ (see UI below).
- BOS integration (identical in pl and whitelabel) ported: `Bos::Client`,
  `Bos::CreateOrderJob`, `Bos::PostMessageJob`, `BosRetryable`, `bos.rake`;
  `ProjectItem::Create` and the project conversation controller enqueue the
  jobs unless running as marketplace. `BOS_ENABLED` / `BOS_API_URL` /
  `BOS_API_KEY` and the `orders` Sidekiq queue were already configured here.
- `VOCABULARY_TYPES` (backoffice vocabularies): marketplace keeps its V6 set;
  pl and whitelabel get their full set in their order, so the backoffice
  vocabulary routes follow the variant.
- Configuration: Devise and the cookie rotator use
  `Rails.application.secret_key_base` (covers pl's `SECRET_KEY_BASE` and
  marketplace's credentials); Check-in accepts pl/whitelabel's
  `CHECKIN_ISSUER_ENDPOINT` / `CHECKIN_JWK_ENDPOINT` next to marketplace's
  names, works without a `checkin` credentials key, and requests the
  `entitlements` scope by default only on marketplace; the STOMP, xGUS and
  reCAPTCHA settings no longer raise when the credentials key is absent.
  Kept as marketplace's: the STOMP YAML shapes (this repo's subscriber reads
  them), the credentials fallbacks whitelabel dropped from `storage.yml` /
  `xgus.yml`, and the EOSC Explore default URL (whitelabel sets
  `EOSC_EXPLORE_BASE_URL`).
- PL registry import: `Importers::Service`, `Importers::Provider` and
  `Importers::Datasource` add pl's V5 field mapping on top of the shared
  V6 mapping under `Mp::Variant.pl?`; `Importable` carries pl's mapping
  helpers. The V5 data lands in structures every variant already has: the
  pl profiles, and the shared `contacts`, `links`, `service_vocabularies`,
  `provider_vocabularies`, `service_relationships`,
  `provider_scientific_domains` and `persistent_identity_systems` tables,
  so no new satellite table was needed. `Service` and `Provider` regained
  pl's association declarations over those tables (empty elsewhere) and the
  `PersistentIdentitySystem` models were restored. Whitelabel's importer
  differences were already covered by this repo's JMS handling.
- Rake tasks: `add_providers_default_logo` uses pl's working loop (the
  marketplace version called the method on the array); `rdt:repair_language_data`
  runs pl's alpha-2 repair under pl only (the field lives in the pl profile);
  `rdt:add_internal_vocabularies` creates pl's research activities from the
  section ported into `db/internal_vocabulary.yml` under pl only.
- Backoffice policy rules: pl and whitelabel open the provider list and
  creation to any signed-in user (whitelabel also the provider page; pl the
  page to editors), use `management_role?` for service creation and
  `actionable?` for editing/destroying services, show deleted services, and
  never lock registry-imported services or providers to internal fields;
  marketplace keeps its rules. The base backoffice policy, the datasource
  policy rules and the vocabulary-based policies (category, platform,
  scientific domain, target user) are equivalent in all three repos; pl's and
  whitelabel's offer/bundle/orderable policies are pre-polymorphic versions
  of marketplace's. Permitted attributes follow the variant: pl's service,
  provider and datasource lists, whitelabel's `node_ids` scalar and no
  `owner_ids`, bundle `research_activity_ids` instead of
  `marketplace_location_ids`; `Service` and `Provider` accept the nested
  contact, link and persistent-identity attributes pl's forms post.
- Test suite: the order-dependent failures in `spec/lib/import` and
  `spec/lib/ordering_api` came from `simple_recommender_spec`'s
  `before :context` seeding, which outlived the per-example transaction; it
  now truncates in `after(:context)`, and the combined models + services +
  lib run passes in defined order.
- UI mechanism (see the decision under UI below): `request.variant` follows
  `Mp::Variant`, so `*.html+pl.haml` / `*.html+whitelabel.haml` templates
  select per variant; `Presentable::StatusActionsComponent` has pl's and
  whitelabel's templates, whitelabel's
  `Backoffice::Services::UnpublishesController` and route are drawn under
  whitelabel, `Presentable::LinksHelper` shows pl's profile links under pl,
  `CUSTOMIZATION_PATH` also overrides images (declared for precompilation),
  JavaScript files (`javascript/`, `config/esbuild.config.js`) and
  stylesheets (`stylesheets/`, `config/sass.config.js`), entries included,
  and `RECAPTCHA_ENABLED=false` disables reCAPTCHA.
- Data model leftovers resolved by keeping marketplace's model:
  `ServiceUserRelationship` (service owners) and `MarketplaceLocation` stay
  for every variant and are simply unused on pl/whitelabel; `Offer` here is
  the polymorphic superset of both other repos (`service`/`service=` compat
  accessors), so nothing was ported from them.
- Customization directories assembled (2026-09-17) as
  `/Users/zlekki/Projects/cyfronet/pl-customization` and
  `whitelabel-customization` (siblings of the repositories, inside none) by
  `assemble_customization.sh` next to them: the views that differ or are
  missing here (169 pl / 164 whitelabel entries), locales (2 / 3), images
  (37 / 20), the seven stylesheet partials and the JavaScript files that
  differ (3 / 5). Verified: the CSS and JS bundles build with each
  directory, and the public, services, backoffice, projects and users
  request specs run under pl and whitelabel with it without template
  errors (the remaining failures are the marketplace-only infrastructure
  route and the cascading provider delete, both expected there).
- Helpers the pl/whitelabel views call: `Presentable::DetailsHelper` returns
  pl's V5 service, datasource and provider sections under pl (classification,
  marketing, maturity, financial information, identifiers, datasource
  content, provider maturity) and carries the datasource policy, persistent
  identity system and research product sections on every variant;
  `Backoffice::ProvidersHelper` gained pl's `cant_edit`, `extended_steps`,
  `safe_tab`, `safe_step` and its Next/Back labels under pl;
  `Backoffice::CataloguesHelper#cant_edit_catalogue`,
  `ApplicationHelper#enable_commons` (`ENABLE_COMMONS`), `#footer_params`
  and `#lead_class`, `FormsHelper#render_persistent_identity_system`,
  `SearchLinksHelper#resource_organisation_detail_path` (and the positional
  `providers(service, backoffice)` call) and
  `ApplicationController#tour_disabled` were added.
- Test suite: the whitelabel unpublish request spec restored only
  `whitelabel?` before reloading routes, so every later spec in a
  defined-order run lost the marketplace-only routes; it now restores all
  three predicates.
- Dev seeds: `dev:prime` / `dev:prime_e2e` load `db/data_pl.yml` /
  `db/data_e2e_pl.yml` under pl and `db/data_whitelabel.yml` /
  `db/data_e2e_whitelabel.yml` under whitelabel (the other repos' datasets,
  copied); marketplace keeps `db/data.yml`. Outside marketplace the task
  seeds pl/whitelabel's V5 provider and service fields (addresses,
  certifications, affiliations, roadmaps, provider vocabularies, tagline,
  manuals, funding, life-cycle status, target users, platforms, contacts;
  provider tags under pl) and picks each service's first category for its
  offers. Verified in the test database: pl fills every service and
  provider profile, whitelabel seeds its own set without profiles,
  marketplace is unchanged.
- `Provider` gained pl's `esfri_type` / `provider_life_cycle_status`
  accessors and `acts_as_taggable`: the pl provider policy here already
  permitted those attributes and pl's classification tab posts them.
- CI: the `variants` job (`ci_backend.yml`) builds the assets and runs
  `spec/requests`, `spec/lib`, `spec/helpers` and `spec/routing` under `pl`
  and `whitelabel` on top of the boot, eager-load and routes checks.
  Examples that exercise marketplace-only behavior carry
  `variant: :marketplace` metadata and are excluded there: the
  infrastructure route, deployable-service pages and ESS API, the
  standalone provider delete, the users API without pl's every-role rule
  and identity lookup, the flat-column simple services API and the SOMBO
  admin lookup by `users.uid`. The user factory builds a primary Check-in
  identity from the uid column under pl (pl-marketplace's factory does),
  built through the `has_one` so an unsaved user already answers `#uid`;
  specs that create identities by hand give the user `uid: nil`. Both
  variant runs pass locally (489 examples each).
- Spring removed (gems, `bin/spring`, `config/spring.rb`, the loader in
  `bin/rspec`): a running preloader served stale code between runs.
- Synchronised with the three `development` branches on 2026-09-21:
  `marketplace` `604134d3` (4.6.0, merged), `pl-marketplace` `ce767a21`,
  `whitelabel-marketplace` `6022b264`.
  - pl: deleted providers are hidden from the backoffice list, and
    `Backoffice::ServicesController#index` authorizes after
    `authenticate_user!` (an unauthenticated user goes through Check-in and
    comes back), both under `Mp::Variant.pl?`; the matching views come from
    the customization directory. The provider pid on saves without validation
    and the `Provider::Draft` fix were already here.
  - whitelabel (#266): its Check-in provider block (mandatory ENV, Keycloak
    defaults, `CHECKIN_DISCOVERY`, `CHECKIN_PORT`, `CHECKIN_SCHEME`,
    `CHECKIN_JWKS_URI`, `CHECKIN_END_SESSION_ENDPOINT`) is used under
    `whitelabel`. `Importers::ClientCredentialsToken` takes the token endpoint
    from that configuration (discovery or client options) and
    `import:authorize` always fetches a token when `MP_IMPORT_TOKEN` is blank,
    both under `Mp::Variant.whitelabel?`. `.env.test` and `.env.build` carry
    dummy values for the mandatory variables (test boot, Docker asset
    precompilation).

## Next steps

Found by comparing `app/`, `lib/` and `config/` of this branch with
`development` of the other two repos (see [Comparison method](#comparison-method)).

### Before any deployment

- [ ] Read `schema_migrations` and real columns on every deployed database;
      compare PL profile rows with the original data. Fix only with new
      migrations. The pl path is verified against the testing dump (see
      Done); a pl database migrated to pl-marketplace's current `development`
      before switching also has `index_users_on_lower_email` instead of
      `index_users_on_email` (its `20260901103100` was not ported) and no
      `users.uid` until `AddNullableUidToUsers` re-adds it. `offer_links`
      stays missing on pl; nothing reads it.
- [ ] Test a whitelabel dump the same way. Whitelabel shares the V6 strip
      versions with this repo, but its `schema.rb` already has
      `deployable_services`, `infrastructures` and the polymorphic
      `offers.orderable_*` columns without this repo's migration versions
      for them (20250806111826 to 20251214143117; whitelabel has
      `MakeOffersOrderable`, 20260429155000, instead). On a whitelabel
      database that has those tables, the `create_table` and `add_column`
      calls in this repo's migrations fail the way the project rename did.
      Whitelabel also ran the rename as 20250510072744 (handled by the
      guard).
- [ ] Check marketplace and whitelabel production databases for duplicate
      provider pids (the pid migration aborts on duplicates; the pl testing
      dump only had blank ones, which are backfilled).
- [ ] The `Dockerfile` runs `assets:precompile` in production without
      `MARKETPLACE_VARIANT`, which `config/initializers/variants.rb` refuses,
      and without `CUSTOMIZATION_PATH`. An image build needs both (build
      arguments, one image per deployment).
- [ ] Keep per-deployment settings: PL's EOSC Commons URL and recommendation
      setting, whitelabel's HTTPS federation URL and `EOSC_EXPLORE_BASE_URL`,
      STOMP/JMS, monitoring, BOS and import settings, `RECAPTCHA_*` keys.

### Delete, lifecycle and messaging (pl + whitelabel)

- [ ] Test JMS handling with real messages from all three deployments.

### PL imports, forms and policies

- [ ] Backoffice provider forms (pl: editable show-page tabs; whitelabel:
      form partials) and service form partials (`_contact`, `_dependencies`,
      whitelabel's `_attribution`, `_availability`, `_datasource_policies`,
      `_financial`, `_location`, `_maturity`): views come from
      `CUSTOMIZATION_PATH` (see UI below); the policies and models already
      accept what they post.
- [ ] Exit modal (identical in pl and whitelabel:
      `common_parts/modals/_exit_modal`, richer `exit_controller.js`, used by
      provider steps and offer forms) and the PL provider approval and profile
      completion modals: views via `CUSTOMIZATION_PATH`; pl/whitelabel's
      `ExitHelper` methods already exist here as `Backoffice::OffersHelper`
      and all helpers are available to every view. The JavaScript
      (`exit_controller.js`) comes from `CUSTOMIZATION_PATH/javascript`.

### UI, branding and configuration

Decision (2026-09-16): variant views, locales and styles are not merged
into this repository. Each deployment points `CUSTOMIZATION_PATH` at a
directory extracted from pl-marketplace or whitelabel-marketplace (their
files that differ from this repo's `app/views`, `config/locales` and
stylesheets); this repository keeps marketplace's views. Code that those
views need (controllers, helpers, components, policies' permitted
attributes) is consolidated here.

Mechanism, per deployment (`CUSTOMIZATION_PATH=/path/to/dir`):

- `views/` and `config/locales/` — prepended to the view and locale paths
  (`config/application.rb`).
- `images/` — prepended to the asset paths (`config/initializers/assets.rb`)
  and added to the precompile list (the manifest links only the
  repository's images); same-named files override the repository's.
- `javascript/` — same-named files override `app/javascript` files when
  `yarn build` runs (`config/esbuild.config.js`), including the
  `application.js` entry; imports from a customized file still resolve to
  the repository's files and `node_modules`. whitelabel's README promised
  this for `CUSTOMIZATION_PATH` but its esbuild config never did it.
- `stylesheets/` — same-named partials and the `application.scss` entry
  override the repository's when `yarn build:css` runs
  (`config/sass.config.js`); every import, also one inside a repository
  partial, is resolved through the customization directory first, so a
  customized `_variables.scss` reaches the partials that re-import it. Bare
  imports resolve from `node_modules`.
- ViewComponent templates cannot come from that directory; components that
  differ per variant carry `<name>.html+pl.haml` / `<name>.html+whitelabel.haml`
  templates in the repository, selected through `request.variant`
  (`ApplicationController#set_variant`). Done for
  `Presentable::StatusActionsComponent` (pl layout; whitelabel turbo frame and
  `polymorphic_path` unpublish/suspend with
  `Backoffice::Services::UnpublishesController` and its route drawn under
  whitelabel). The header, provider-info and list components and
  `Services::InlineOrderUrlComponent` differ only in robustness rewrites.
  `Presentable::LinksHelper` lists pl's profile links and wording under pl;
  `links_component.yml` carries the labels.
- `RECAPTCHA_ENABLED=false` (whitelabel's `customization.rb`) skips the
  reCAPTCHA keys and widget on any variant.

- [ ] Exercise the pages the request specs do not reach against each
      customization directory (provider and catalogue forms, datasource
      pages, offers and bundles, mailers, federation, admin) and port any
      helper or controller method they still miss; then drop from the
      directories the files whose differences turn out cosmetic.

### Review and tests

- [ ] Re-run the comparison after the customization directories exist and
      review what is still "different" (313 vs pl-marketplace, 291 vs
      whitelabel-marketplace on 2026-09-16; most of those files were changed
      here by the consolidation itself, so the number no longer measures
      remaining work).
- [ ] Extend the per-variant CI job further with profile persistence, import
      and JMS fixtures, search reindex and deletion under `pl` and
      `whitelabel` (it now runs the request, lib, helper and routing specs;
      see Done). Note: since the migration squash a fresh database can only
      be built with `db:schema:load`; `db:migrate` on an empty database
      fails at the first remaining migration, so the rspec job was switched
      too.
- [ ] Build a real PL search index from copied PL data and compare results
      with pl-marketplace.

## Comparison method

The history of `pl-marketplace` and `whitelabel-marketplace` still contains
marketplace commits up to `b82db140` (2025-01-20) and `be8c9a1d`
(2025-06-05). Files under `app/`, `lib/` and `config/` that each repo
changed after that commit were compared with this branch.

Original audit (2026-09-15):

| | pl-marketplace | whitelabel-marketplace |
|---|---|---|
| Already identical here | 251 | 319 |
| Missing here | 46 | 64 |
| Different, changed only in that repo | 63 | 74 |
| Different, marketplace changed it too | 173 | 144 |
| Added independently in both | 53 | 47 |
| Deleted there, still here | 20 | 19 |

After the 2026-09-16 batches (same file sets, compared byte for byte; the
consolidation changed many of these files here, so "different" now includes
files that are gated rather than missing):

| | pl-marketplace | whitelabel-marketplace |
|---|---|---|
| Already identical here | 269 | 331 |
| Missing here | 29 | 50 |
| Different | 313 | 291 |

Of the missing files, 17 / 18 are images and 6 / 26 are views, both covered
by the `CUSTOMIZATION_PATH` decision; the code files are listed under
"Variant-only features".
