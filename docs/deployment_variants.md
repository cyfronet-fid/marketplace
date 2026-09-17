# Deployment variants

`marketplace`, `pl-marketplace`, and `whitelabel-marketplace` are consolidating
onto this single codebase (ADR-0001: single codebase over per-node forks).
Which node a running process behaves as is selected at boot by the
`MARKETPLACE_VARIANT` env var (`marketplace` / `pl` / `whitelabel`), validated
against `config/variants.yml` and exposed via `Mp::Variant` (`lib/mp/variant.rb`).
Unset defaults to `marketplace` in development and test; a production boot
raises without it (`config/initializers/variants.rb`).

Use `Mp::Variant.marketplace?` / `.pl?` / `.whitelabel?` to key off it. Prefer
a config/env toggle for genuine per-deployment behavior; if two repos' code
only *looked* different but did the same thing, it was unified instead of
gated.

## What's been ported so far

- `Api::ServicesController` — `COUNTRY_NAME`/`CONTACT_EMAIL` now serve real
  data (via a restored `geographical_availabilities` column and a
  `Service#public_contacts` association) under `pl`; `marketplace` and
  `whitelabel` keep the flat/empty behavior (whitelabel's own `Service`
  stubbed both fields, so its endpoint raised on `includes(:public_contacts)`).
- `Api::V1::Ess::ApplicationController` — the `deployable_services` ESS
  collection/route is `marketplace`-only (the underlying `DeployableService`
  data model doesn't exist on `pl`/`whitelabel`).
- `ApplicationController#publish_user_actions_to_jms?` — JMS user-action
  publishing now actually respects `mp_stomp_publisher_enabled` (previously
  dead config on all three repos).
- `DataAdministrator#connect_user` — fixed an unguarded counter decrement.
- `Api::V1::UsersController` — fixed a 404 message referencing the wrong
  param key.
- `Importers::ClientCredentialsToken` — normal import tasks can obtain a token
  automatically when `IMPORT_CLIENT_ID`, `IMPORT_CLIENT_SECRET`, and the
  Check-in token endpoint are configured. `MP_IMPORT_TOKEN` still takes
  precedence, and the legacy refresh-token client remains separate.
- `Provider#pid` — ported from pl-marketplace for all variants (not gated):
  generated as a UUID when blank, validated present/unique, and enforced
  `NOT NULL` + unique index by `EnforceNotNullUniquePidOnProviders`, which
  keeps pl's migration version.
- Delete/suspend/unpublish lifecycle — selected per variant by
  `VariantOperation` (`app/services/variant_operation.rb`): `marketplace` uses
  the `*::Standalone` implementations and `Service/Offer/Bundle::Destroy`;
  `pl`/`whitelabel` use `*::Cascading` and `Service/Offer/Bundle::Delete`,
  which enqueue `DeleteJob`/`SuspendJob`/`UnpublishJob` for dependent records.
- `Jms::ManageMessage` — accepts `resource` as a JSON string (all variants).
- `Service::Publish` — pl/whitelabel ordering for all variants: offer
  publish, bundled-offer notifications and subscriber mail happen only after
  `update(status: :published)` succeeds; a failed update returns `false`.
- Public `deployable_services` routes (pages, logo, ordering wizard) and the
  project `infrastructure` destroy route exist only under `marketplace`;
  `Jms::ManageMessage` raises `WrongMessageError` for `deployable_application`
  messages on the other variants, as their own subscribers do. The
  `DeployableService::*` jobs and services stay unreachable there.
  `Ams::ProcessMessage` is not gated.
- Login identities — `UserIdentity`, `Users::Authenticate` and the
  `user_identities` table exist everywhere; `users.uid` stays, nullable. Under
  `pl` the Check-in callback, `Api::V1::UsersController`, `User#uid`, the
  email-uniqueness validation and the `lib/ordering_api` admin setup go
  through identities; `marketplace`/`whitelabel` keep `User::Checkin` and
  `users.uid`. `session["token"]` is set after login only on `marketplace`.
- `Ess::Add` / `Propagable#propagate_to_ess` — pl's `propagate_offers:`
  option for all variants (default `true` keeps current behavior). Under `pl`
  datasources go to ESS with `Ess::DatasourceSerializer` and `Offer::Create`
  pushes the service to ESS after saving the offer; other variants send every
  service with `Ess::ServiceSerializer` and only reindex.
- `Api::V1::UserPolicy#show?`, `OrderingApi::AddSombo` (admin gets every
  role) and `OrderingApi::AddProviderOMS` (`underscore` instead of
  `downcase`) — pl behavior under `pl`, unchanged elsewhere.
- `Api::V1::Catalogue::ServicesController` (`/api/v1/catalogue/services`,
  `v1/catalogue_swagger.json`) — pl's public catalogue API; the route is drawn
  only under `pl`. `Service#access_modes` and `Service#logo_url` exist on
  every variant for its serializer.
- `Federation::ServicesController#map_results` — whitelabel's fallbacks to
  `result.service.*` for name, description, webpage, logo and nodePID, for all
  variants (`dig`, so absent keys stay `nil`).
- BOS (`Bos::Client`, `Bos::CreateOrderJob`, `Bos::PostMessageJob`,
  `bos:sync_users` / `bos:sync_providers`) — ported from pl/whitelabel;
  `ProjectItem::Create` and `Projects::Services::ConversationsController`
  enqueue the jobs unless `Mp::Variant.marketplace?`. `BOS_ENABLED`,
  `BOS_API_URL`, `BOS_API_KEY` configure the client.
- Configuration — Devise and `cookie_rotator.rb` use
  `Rails.application.secret_key_base`; Check-in reads `CHECKIN_ISSUER_ENDPOINT`
  and `CHECKIN_JWK_ENDPOINT` as well as `CHECKIN_JWKS_ENDPOINT`, tolerates a
  missing `checkin` credentials key, and adds the `entitlements` scope to the
  default only under `marketplace`; STOMP, xGUS and reCAPTCHA credential
  lookups are nil-safe.
- `Importers::Service` / `Importers::Provider` / `Importers::Datasource` —
  under `pl` the V5 registry payload fields (tagline and the other profile
  fields, service categories, funding, life-cycle statuses, contacts, links,
  related/required services, platforms, provider location, ESFRI/MERIL,
  networks, data administrators, datasource policies) are mapped on top of
  the shared V6 mapping into the pl profiles and the shared join tables.
  Other variants keep the V6 mapping only.
- `Backoffice::ProviderPolicy` / `Backoffice::ServicePolicy` — under `pl`
  and `whitelabel` any signed-in user may list and create providers
  (`whitelabel` also view them; `pl` shows them to editors), service creation
  needs `management_role?`, editing/destroying a service needs
  `actionable?`, deleted services are viewable, and registry-imported
  records are not locked to internal fields. `marketplace` keeps its rules.
  Permitted attributes follow the variant (pl's V5 form fields, whitelabel's
  `node_ids` scalar without `owner_ids`, bundle `research_activity_ids`);
  the forms themselves come from `CUSTOMIZATION_PATH`.
- `CUSTOMIZATION_PATH` — per-deployment `views/`, `config/locales/`,
  `images/` (also precompiled), `javascript/` and `stylesheets/` override the
  repository's same-named files. `config/esbuild.config.js` and
  `config/sass.config.js` resolve every import, and the `application.js` /
  `application.scss` entries, through the customization directory first
  (whitelabel's README promised this for JS and SCSS but its build never did
  it). pl and whitelabel keep their seven differing stylesheet partials,
  `controllers/exit_controller.js`, `controllers/form_controller.js` and
  `app/cookies_policy.js` there, whitelabel also `application.js` and
  `controllers/form_redirect_controller.js`; pl's `dialog` Stimulus
  controller is in the repository bundle. The directories themselves live
  next to the repositories (`pl-customization`, `whitelabel-customization`,
  built by `assemble_customization.sh`).
- Helpers the pl/whitelabel views call — `Presentable::DetailsHelper` returns
  pl's V5 detail sections under `pl` and carries the datasource policy,
  persistent identity system and research product sections everywhere;
  `Backoffice::ProvidersHelper#cant_edit`, `#extended_steps`, `#safe_tab`,
  `#safe_step` (Next/Back labels without arrows under `pl`),
  `Backoffice::CataloguesHelper#cant_edit_catalogue`,
  `ApplicationHelper#enable_commons` (`ENABLE_COMMONS`), `#footer_params`,
  `#lead_class`, `FormsHelper#render_persistent_identity_system`,
  `SearchLinksHelper#resource_organisation_detail_path` and
  `ApplicationController#tour_disabled` exist on every variant. `request.variant` is set from `Mp::Variant`
  (`ApplicationController#set_variant`) so `*.html+pl.haml` /
  `*.html+whitelabel.haml` templates win, which is how
  `Presentable::StatusActionsComponent` differs per variant; under
  `whitelabel` it unpublishes/suspends services through
  `Backoffice::Services::UnpublishesController`. `Presentable::LinksHelper`
  shows pl's profile links under `pl`. `RECAPTCHA_ENABLED=false` disables
  reCAPTCHA keys and widget on any variant.
- `VOCABULARY_TYPES` — `marketplace` keeps its ten V6 vocabulary types; `pl`
  and `whitelabel` manage the full set (target users, access modes, funding
  bodies/programs, life-cycle statuses, ESFRI, MERIL, research activities,
  entity types, product access policies, service categories, …) and the
  backoffice `other_settings/vocabularies` routes follow.
- `Backoffice::Vocabulary::ResearchActivityPolicy` and
  `Recommender::Vocabulary::ResearchActivitySerializer` exist on every
  variant; `RecommenderLib::SerializeDb` dumps `research_activities` under
  `pl`/`whitelabel` and `research_steps` (marketplace locations) under
  `marketplace`.
- `Provider::Draft` (whitelabel's save-as-draft) reindexes the provider like
  whitelabel's `Provider::CreateAsDraft`. `Catalogue::PcDelete` (no caller in
  any repo) and `Provider::PcDelete` (covered by `Provider::Delete`) were not
  ported.
- `OrderingApi::AuthorizationTestSetup` creates the sample services with a
  tagline and a geographical availability under `pl`/`whitelabel`; it also
  sets the provider fields and offer category the current models require
  (it failed on every repo without them).
- `dev:prime` / `dev:prime_e2e` — `db/data.yml` and `db/data_e2e.yml`
  under `marketplace`, `db/data_<variant>.yml` / `db/data_e2e_<variant>.yml`
  (the other repos' datasets) under `pl` and `whitelabel`, where the task
  also seeds the V5 provider and service fields the way pl's and
  whitelabel's `dev.rake` did (provider tags only under `pl`).
- `Provider#esfri_type`, `#provider_life_cycle_status` and `tag_list`
  (`acts_as_taggable`) exist on every variant; pl's provider forms post them.
- `config.whitelabel`/`MP_WHITELABEL` was folded into `Mp::Variant.whitelabel?`.
- `config.monitoring_data_token` — no longer raises on a deployment whose
  `credentials.yml.enc` lacks the `monitoring_data` key; falls back to `nil`
  instead (all variants, not gated — a bug fix, not a behavior difference).
- `SearchLinksHelper#resource_organisation`/`#providers` — under `pl`/
  `whitelabel`, the organisation/provider name in a service's header links
  straight to the provider's own detail page; `marketplace` keeps its
  search-highlighting/preview-aware filtered-search link unchanged.

## Full details

The per-controller diffs, rationale, and audit methodology behind each of the
above live in the `arch_docs` repo, not here:

- `docs/adr/0001-single-codebase-over-per-node-forks.md` — the consolidation
  decision and migration path.
- `docs/rationale/controllers-comparison.md` and `docs/rationale/controllers/`
  — full three-way controller diff, file by file.
- `docs/rationale/whitelabel-feature-audit.md` — whitelabel's independent
  commits since the fork, sorted into verified gaps, needs-a-closer-look, and
  client-specific/excluded.

Anything not listed above under "What's been ported so far" is either not yet
reviewed, or was deliberately left out (see the audit's own client-specific
and excluded sections) — check there before assuming a given behavior has
been reconciled.
