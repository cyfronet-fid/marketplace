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

## Next steps

Found by comparing `app/`, `lib/` and `config/` of this branch with
`development` of the other two repos (see [Comparison method](#comparison-method)).

### Before any deployment

- [ ] Read `schema_migrations` and real columns on every deployed database;
      compare PL profile rows with the original data. Fix only with new
      migrations.
- [ ] Check marketplace and whitelabel production databases for duplicate
      provider pids (the pid migration aborts on duplicates).
- [ ] Make `MARKETPLACE_VARIANT` required in production.
- [ ] Keep per-deployment settings: `SECRET_KEY_BASE`, Check-in endpoint
      variable names, PL's EOSC Commons URL and recommendation setting,
      whitelabel's HTTPS federation URL, STOMP/JMS, monitoring, BOS and import
      settings. Devise should use `Rails.application.secret_key_base`.

### Delete, lifecycle and messaging (pl + whitelabel)

- [ ] Test JMS handling with real messages from all three deployments.

### PL imports, forms and policies

- [ ] Full PL field mapping in `importers/service.rb`, `provider.rb`,
      `datasource.rb` and `concerns/importable.rb`.
- [ ] Backoffice provider forms (pl: editable show-page tabs; whitelabel:
      form partials) and service form partials (`_contact`, `_dependencies`,
      whitelabel's `_attribution`, `_availability`, `_datasource_policies`,
      `_financial`, `_location`, `_maturity`).
- [ ] Exit modal and `ExitHelper`; PL provider approval and profile
      completion modals; whitelabel `Backoffice::Services::UnpublishesController`.
- [ ] Policies: `service`, `datasource`, `provider`, `bundle`, `category`,
      `scientific_domain`, `platform`; research-activity policy and
      recommender serializer.

### Variant-only features

- [ ] Decide on BOS integration (`services/bos`, `jobs/bos`, `bos.rake`) —
      whitelabel audit marks it client-specific.
- [ ] PL Catalogue API (`Api::V1::Catalogue::ServicesController`, policy,
      serializers).
- [ ] PL login identities: `UserIdentity`, `Users::Authenticate` (replaces
      `User::Checkin`, prevents duplicate accounts).
- [ ] PL SOMBO/OMS role fixes in `lib/ordering_api`; `Propagable`
      `propagate_offers:` option.
- [ ] Whitelabel search API and federation (`Api::V1::Search`,
      `Federation::ServicesController` and views).

### Data model leftovers

- [ ] `MarketplaceLocation` replaced by research activity in both other repos.
- [ ] `ServiceUserRelationship` (service owners) removed in both other repos.
- [ ] `Offer` model and `config/initializers/constants.rb` differences.

### UI, branding and configuration

- [ ] Styles (`_bootstrap-customizations.scss`, variables), landing and home
      pages, navbar/sections layouts, EOSC Commons footer, admin views,
      whitelabel `customization.rb`, images — via variant partials/assets or
      `CUSTOMIZATION_PATH`.
- [ ] Config: `devise.rb`, `stomp_publisher.yml`, `stomp_subscriber.yml`,
      whitelabel `recaptcha.rb`, `cookie_rotator.rb`, `storage.yml`,
      `xgus.yml`, `eosc_explore_banner.yml`.
- [ ] Rake tasks: `dev.rake`, `rdt.rake`, PL `add_providers_default_logo.rake`.

### Review and tests

- [ ] Diff the files changed on both sides (173 vs pl-marketplace, 144 vs
      whitelabel-marketplace) and decide port / gate / already covered.
- [ ] CI job per variant (separate process, database, Redis, Elasticsearch):
      boot, routes, public and backoffice page, profile persistence, import
      and JMS fixtures, search reindex, deletion.
- [ ] Fix order-dependent failures in `spec/lib/import/resources_spec.rb` and
      `spec/lib/ordering_api/*` (pass alone, fail in a combined run).
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
