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

ESS and ordering API:

- `Propagable#propagate_to_ess` and `Ess::Add` take pl's `propagate_offers:`
  option (default unchanged). Under pl, datasources are sent to ESS with the
  datasource profile and `Offer::Create` pushes the service to ESS after
  saving the offer; the other variants keep sending datasources as services
  and only reindex.
- pl's users API rule (`Api::V1::UserPolicy#show?` requires every role), the
  SOMBO admin holding every role and `AddProviderOMS` underscoring the OMS
  name are gated to pl.
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
- Data model leftovers resolved by keeping marketplace's model:
  `ServiceUserRelationship` (service owners) and `MarketplaceLocation` stay
  for every variant and are simply unused on pl/whitelabel; `Offer` here is
  the polymorphic superset of both other repos (`service`/`service=` compat
  accessors), so nothing was ported from them.

## Next steps

Found by comparing `app/`, `lib/` and `config/` of this branch with
`development` of the other two repos (see [Comparison method](#comparison-method)).

### Before any deployment

- [ ] Read `schema_migrations` and real columns on every deployed database;
      compare PL profile rows with the original data. Fix only with new
      migrations. Tables in this schema that pl's schema lacks:
      `deployable_service_scientific_domains`, `deployable_service_sources`,
      `deployable_services`, `infrastructures`, `offer_links`,
      `service_user_relationships` (plus the pl profile tables and
      `user_identities`, created by this repo's own migrations); whitelabel's
      schema lacks the five PL-only tables restored by `RestorePlOnlyTables`,
      the pl profile tables and `user_identities`. Make sure the pl database
      gets the marketplace-only tables through a forward migration.
- [ ] Check marketplace and whitelabel production databases for duplicate
      provider pids (the pid migration aborts on duplicates).
- [ ] Make `MARKETPLACE_VARIANT` required in production.
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
      (`exit_controller.js`) is bundled from the repo and still differs.

### Variant-only features

- [ ] `OrderingApi::AuthorizationTestSetup` service attributes: pl and
      whitelabel create the sample services with `tagline` and
      `geographical_availabilities` instead of `categories` and `order_type`.

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
- `images/` — prepended to the asset paths (`config/initializers/assets.rb`);
  same-named files override the repository's.
- stylesheets — `CSS_ENTRY=$CUSTOMIZATION_PATH/stylesheets/application.scss`
  for `yarn build:css`; the entry imports its own partials (variables,
  bootstrap customizations, design system) and the repository's through the
  `app/assets/stylesheets` load path.
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

- [ ] Assemble the pl and whitelabel customization directories from their
      repos: the views (backoffice, services, layouts, home/pages, providers,
      projects, mailers, federation), locales, the seven stylesheet files
      (`_variables`, `_bootstrap-customizations`, `designsystem`, `_flash`,
      `_order`, `_ref_*`) as a `stylesheets/application.scss` entry with its
      partials, and the differing images; then run each variant's pages
      against it.
- [ ] `exit_controller.js` and other `app/javascript` differences are bundled
      from the repository (esbuild); decide variant handling there.
- [ ] Dev seeds: pl's `db/data.yml` is a different V5 sample dataset
      (addresses, funding, life-cycle statuses, platforms, target users) and
      its `dev.rake` seeds those fields; this repo keeps marketplace's seeds
      (nodes, deployable services). Port pl's seed data under `pl` if pl
      developers need `dev:prime` to fill the profiles.

### Review and tests

- [ ] Diff the files changed on both sides (173 vs pl-marketplace, 144 vs
      whitelabel-marketplace) and decide port / gate / already covered.
- [ ] Extend the per-variant CI job (`variants` in `ci_backend.yml`: fresh
      database from `db/schema.rb`, eager load, routes, routing specs under
      `pl` and `whitelabel`) with public and backoffice pages, profile
      persistence, import and JMS fixtures, search reindex and deletion.
      Note: since the migration squash a fresh database can only be built
      with `db:schema:load`; `db:migrate` on an empty database fails at the
      first remaining migration, so the rspec job was switched too.
- [ ] Build a real PL search index from copied PL data and compare results
      with pl-marketplace.

## Comparison method

The history of `pl-marketplace` and `whitelabel-marketplace` still contains
marketplace commits up to `b82db140` (2025-01-20) and `be8c9a1d`
(2025-06-05). Files each repo changed after that commit were compared with
this branch:

| | pl-marketplace | whitelabel-marketplace |
|---|---|---|
| Already identical here | 251 | 319 |
| Missing here | 46 | 64 |
| Different, changed only in that repo | 63 | 74 |
| Different, marketplace changed it too | 173 | 144 |
| Added independently in both | 53 | 47 |
| Deleted there, still here | 20 | 19 |
