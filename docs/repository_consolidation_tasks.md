# Tasks for merging the three Marketplace repositories

This file replaces GitHub subtasks #3770–#3776 linked to
[marketplace#3752](https://github.com/cyfronet-fid/marketplace/issues/3752).
No new GitHub issues were created.

## What we are building now

One repository must run these three separate deployments:

```text
MARKETPLACE_VARIANT=marketplace
MARKETPLACE_VARIANT=pl
MARKETPLACE_VARIANT=whitelabel
```

The deployments will continue to use separate databases and secrets.
Temporary `Mp::Variant` checks and copied compatibility code are allowed. We
will clean this up after all three deployments use this repository.

Some migrations have already run. Never change or roll back an applied
migration. Any database fix must be a new migration with a newer timestamp.

The detailed review is in `docs/whitelabel_integration_review.md`.

## Current work state

Status meanings:

- **Done on branch** — committed on `feat/whitelabel-integration`.
- **Proposed** — present only as an uncommitted change and waiting for review.
- **Partial** — some code exists, but the task is not complete or safe to
  deploy yet.
- **Not started** — no matching implementation was found in the merged repo.

### Done on branch

| Work | Status | Main files |
|---|---|---|
| Select `marketplace`, `pl`, or `whitelabel` at boot | Done on branch | `lib/mp/variant.rb`, `config/variants.yml`, `config/initializers/variants.rb` |
| Reject an unknown variant | Done on branch | `config/initializers/variants.rb` |
| Replace the old whitelabel helper/config reads with `Mp::Variant` | Done on branch | `app/helpers/application_helper.rb`, `app/components/presentable/header_component.rb` |
| Hide deployable services from the ESS API for PL/whitelabel | Done on branch | `config/routes.rb`, `app/controllers/api/v1/ess/application_controller.rb` |
| Use PL/whitelabel contact and country data in the simple services API | Done on branch | `app/controllers/api/services_controller.rb`, `app/models/service.rb` |
| Make missing monitoring credentials return `nil` | Done on branch | `config/application.rb` |
| Make the STOMP/JMS enable flag control publishing | Done on branch | `config/application.rb`, `app/controllers/application_controller.rb`, `app/controllers/user_action_controller.rb`, `app/controllers/services/summaries_controller.rb` |
| Fix the user API error message parameter | Done on branch | `app/controllers/api/v1/users_controller.rb` |
| Guard the DataAdministrator counter update | Done on branch | `app/models/data_administrator.rb` |
| Link provider names directly for PL/whitelabel | Done on branch | `app/helpers/search_links_helper.rb`, `app/components/presentable/header_component.html.haml` |
| Rename marketplace's remote Service delete operation to avoid a class-name conflict | Done on branch | `app/services/service/pc_delete.rb`, `app/jobs/service/delete_job.rb` |
| Create PL Service/Provider profile tables and copy old data | Done on branch, needs database verification | `db/migrate/20260909100000_create_service_pl_profiles.rb` through `20260909100300_backfill_provider_pl_profiles.rb` |
| Remove old PL profile columns | Done on branch and already run on some apps; forward fixes only | `db/migrate/20260909100400_remove_pl_legacy_columns_from_services.rb`, `db/migrate/20260909100500_remove_pl_legacy_columns_from_providers.rb` |
| Add a whitelabel provider “Save as draft” path | Partial | `app/controllers/backoffice/providers/steps_controller.rb`, `app/services/provider/draft.rb`, `app/views/backoffice/providers/steps/_buttons.html.haml` |

### Proposed and waiting for review

| Work | Status | Main files |
|---|---|---|
| Build and autosave missing PL profiles for new Service/Provider records | Proposed | `app/models/service.rb`, `app/models/provider.rb` |
| Restore PL country conversion for geographic/profile fields | Proposed | `app/models/concerns/presentable.rb`, `app/models/service/pl_profile.rb`, `app/models/provider/pl_profile.rb` |
| Add PL research activities and target-user associations/helpers | Proposed | `app/models/service.rb`, `app/models/vocabulary/research_activity.rb`, `app/helpers/service_helper.rb` |
| Add PL search fields and filters without changing other index shapes | Proposed | `app/models/service/search.rb`, `app/controllers/concerns/service/searchable.rb`, `app/models/filter/research_activity.rb` |
| Port whitelabel client-credentials import login and wire it to import tasks | Proposed | `app/services/importers/client_credentials_token.rb`, `app/services/importers/token.rb`, `lib/tasks/import.rake` |
| Block crafted “Save as draft” requests outside whitelabel | Proposed | `app/controllers/backoffice/providers/steps_controller.rb` |
| Add focused specs for the proposals above | Proposed; 32 examples pass | matching files under `spec/` |
| Explain the temporary Offer delete split | Done as requested | `app/services/offer/delete.rb`, `app/services/offer/destroy.rb` |
| Restore `Service#platforms` and index it for PL's platform filter | Proposed | `app/models/service.rb`, `app/models/service/search.rb` |
| Serve simple services API contacts/countries only for PL (whitelabel's own endpoint raised; its data matches marketplace) | Proposed | `app/controllers/api/services_controller.rb` |
| Restore PL-only tables on marketplace/whitelabel databases so all variants share one schema | Proposed; verified on a throwaway database (create path, no-op path, identical schema dump) | `db/migrate/20260915100000_restore_pl_only_tables.rb` |
| Port PL's required unique Provider `pid` (generated when blank, including on `save(validate: false)` such as `Provider::Draft`) to all variants | Proposed; the migration keeps PL's version so databases that already ran it skip it. It aborts if a database has duplicate pids | `db/migrate/20260911143014_enforce_not_null_unique_pid_on_providers.rb`, `app/models/provider.rb` |

### Remaining task status

| Task | Status |
|---|---|
| Task 1 — Database audit and forward repair | Partial: migrations exist, real database state is still needed |
| Task 2 — PL persistence/import/forms | Partial: profile proposal exists; full import and form behavior is missing |
| Task 3 — Delete and event behavior | Not started, except the Offer comments |
| Task 4 — Variant-only routes/tasks/workers | Partial: ESS route and proposed import-task guard exist |
| Task 5 — PL search and APIs | Partial/proposed: unit-level implementation exists; real reindex/API proof is missing |
| Task 6 — UI, authentication, and deployment settings | Partial: only a few whitelabel/controller differences were ported |
| Task 7 — Three-variant CI and cutover | Not started; manual boot checks passed |

## Task 1 — Check every deployed database before running more migrations

**Current status: Partial.** Migration code exists, but the real database
state and any needed forward repair are not known yet.

### Why

The same migration files did not run in the same way on every database. Some
databases may already have PL profile tables or may already have removed the
old columns.

### Check these files

- `db/migrate/20260429131000_strip_provider_to_v6.rb`
- `db/migrate/20260429141000_strip_service_to_v6.rb`
- `db/migrate/20260429150000_strip_datasource_to_v6.rb`
- `db/migrate/20260909100000_create_service_pl_profiles.rb`
- `db/migrate/20260909100100_create_provider_pl_profiles.rb`
- `db/migrate/20260909100200_backfill_service_pl_profiles.rb`
- `db/migrate/20260909100300_backfill_provider_pl_profiles.rb`
- `db/migrate/20260909100400_remove_pl_legacy_columns_from_services.rb`
- `db/migrate/20260909100500_remove_pl_legacy_columns_from_providers.rb`
- `db/schema.rb`
- `../pl-marketplace/db/schema.rb`
- `../whitelabel-marketplace/db/schema.rb`

### Work

Run this query on every deployed database and save the result:

```sql
SELECT version
FROM schema_migrations
WHERE version IN (
  '20260429131000', '20260429141000', '20260429150000',
  '20260909100000', '20260909100100', '20260909100200',
  '20260909100300', '20260909100400', '20260909100500'
)
ORDER BY version;
```

Also list the real columns:

```sql
SELECT table_name, column_name
FROM information_schema.columns
WHERE table_name IN (
  'services', 'providers', 'service_pl_profiles', 'provider_pl_profiles'
)
ORDER BY table_name, ordinal_position;
```

For PL, compare the number and contents of parent rows and profile rows. If
anything is missing, create a new forward-only repair migration. Do not edit
the migrations listed above.

All variants must end with the same schema. PL-only tables exist on every
database and are used only under `Mp::Variant.pl?`. Migrations that would
delete PL data get a `pl?` guard.
`20260915100000_restore_pl_only_tables.rb` recreates the five tables that
`StripServiceToV6` and `StripDatasourceToV6` dropped outside PL.

Make `MARKETPLACE_VARIANT` required in production. The current default is
`marketplace`, which is unsafe when somebody forgets the variable on a PL
database.

Place to change:

- `config/initializers/variants.rb`
- `config/variants.yml`

Example only:

```ruby
if Rails.env.production? && ENV["MARKETPLACE_VARIANT"].blank?
  raise "MARKETPLACE_VARIANT must be set in production"
end
```

### Done when

- We know which migrations ran on every database.
- PL profile row counts and values match the original data or a backup.
- Every needed fix is a new forward-only migration.
- Production cannot start or migrate without an explicit variant.

## Task 2 — Make all PL fields save correctly

**Current status: Partial and waiting for review.** Profile autosave, country
conversion, research activities, target users, and basic specs are proposed.
The full PL importer, forms, policies, and validation behavior are missing.

### Why

Old PL values were copied to profile tables, but new records and future
imports must also write those values. Backoffice forms must still show and
save them.

### Merged-repository files

- `app/models/service.rb`
- `app/models/service/pl_profile.rb`
- `app/models/provider.rb`
- `app/models/provider/pl_profile.rb`
- `app/models/concerns/presentable.rb`
- `app/services/importers/service.rb`
- `app/services/importers/provider.rb`
- `app/services/importers/datasource.rb`
- `app/policies/backoffice/service_policy.rb`
- `app/policies/backoffice/provider_policy.rb`
- `app/controllers/backoffice/providers/steps_controller.rb`
- `app/views/backoffice/services/form/`
- `app/views/backoffice/providers/form/`

### Copy behavior from

- `../pl-marketplace/app/models/service.rb`
- `../pl-marketplace/app/models/provider.rb`
- `../pl-marketplace/app/services/importers/service.rb`
- `../pl-marketplace/app/services/importers/provider.rb`
- `../pl-marketplace/app/services/importers/datasource.rb`
- `../pl-marketplace/app/policies/backoffice/service_policy.rb`
- `../pl-marketplace/app/policies/backoffice/provider_policy.rb`
- `../pl-marketplace/app/views/backoffice/services/form/`
- `../pl-marketplace/app/views/backoffice/providers/form/`

### Work

- Review the current proposal that builds and autosaves missing PL profiles.
- Copy every PL import field, not only the fields shown in the example below.
- Copy PL validation, whitespace cleanup, country conversion, and the
  `horizontal` scope.
- Copy the PL form fields and allow the same parameters in Pundit policies.
- Restore required PL models and associations such as research activities,
  target users, related services/platforms, and persistent identity systems.

A simple temporary importer shape is acceptable:

```ruby
attributes = shared_attributes

if Mp::Variant.pl?
  attributes.merge!(
    tagline: @data["tagline"].presence || "-",
    language_availability: Array(@data["languageAvailabilities"]),
    resource_geographic_locations: Array(@data["resourceGeographicLocations"]),
    target_users: map_target_users(@data["targetUsers"]),
    research_activity_ids: map_research_activity_ids(@data["researchActivities"])
  )
end
```

This snippet is only a pattern. The PL source importer contains the full list.

### Tests to add or extend

- `spec/services/importers/service_spec.rb`
- `spec/services/importers/provider_spec.rb`
- `spec/services/importers/datasource_spec.rb`
- `spec/requests/backoffice/services_spec.rb`
- `spec/requests/backoffice/providers_spec.rb`
- `spec/models/service/pl_profile_spec.rb`
- `spec/models/provider/pl_profile_spec.rb`

### Done when

One fixture with every PL-only field can be imported, edited, saved, and
reloaded without losing data. Marketplace and whitelabel must not create PL
profile rows.

## Task 3 — Keep the old delete and event behavior for each variant

**Current status: Not started.** Only comments explaining the temporary
`Offer::Delete`/`Offer::Destroy` split have been added.

### Why

The three apps do not delete Services, Providers, Offers, Bundles, and related
records in the same way. Using only the marketplace code can leave PL records
active after a remote delete event.

### Merged-repository files

- `app/services/service/pc_delete.rb`
- `app/services/service/destroy.rb`
- `app/services/offer/delete.rb`
- `app/services/offer/destroy.rb`
- `app/services/provider/delete.rb`
- `app/services/catalogue/delete.rb`
- `app/services/datasource/delete.rb`
- `app/jobs/service/delete_job.rb`
- `app/jobs/provider/delete_job.rb`
- `app/jobs/datasource/delete_job.rb`
- `app/controllers/backoffice/services_controller.rb`
- `app/controllers/services/ordering_configuration/offers_controller.rb`
- `app/controllers/api/v1/resources/offers_controller.rb`
- `app/services/jms/manage_message.rb`
- `app/services/ams/process_message.rb`

### Copy behavior from

- `../pl-marketplace/app/services/service/delete.rb`
- `../pl-marketplace/app/services/service/pc_delete.rb`
- `../pl-marketplace/app/services/provider/delete.rb`
- `../pl-marketplace/app/services/provider/pc_delete.rb`
- `../pl-marketplace/app/services/catalogue/delete.rb`
- `../pl-marketplace/app/services/catalogue/pc_delete.rb`
- `../pl-marketplace/app/jobs/delete_job.rb`
- `../pl-marketplace/app/services/jms/manage_message.rb`
- the equivalent files under `../whitelabel-marketplace/`

### Work

Keep both implementations and select the old behavior directly:

```ruby
operation = Mp::Variant.marketplace? ? Service::Destroy : Service::Delete
operation.call(@service)
```

Use the same temporary pattern for `Offer::Destroy` versus `Offer::Delete`,
and for PC delete jobs.

The PL/whitelabel JMS message can store `resource` as a JSON string. Accept
both a string and a hash:

```ruby
event_body = body["resource"] || body
event_body = JSON.parse(event_body) if event_body.is_a?(String)
```

Keep the temporary compatibility comments in `Offer::Delete` and
`Offer::Destroy`.

### Tests to add or extend

- `spec/services/offer/destroy_spec.rb`
- `spec/services/service/pc_delete_spec.rb`
- `spec/jobs/service/delete_job_spec.rb`
- `spec/services/jms/manage_message_spec.rb`
- `spec/services/ams/manage_message_spec.rb`

Use real example event bodies from all three deployments.

### Done when

Create, update, and delete events produce the same database changes and jobs
as the old app for each variant.

## Task 4 — Hide features that do not belong to a variant

**Current status: Partial.** ESS deployable-service routes are guarded and an
import-task guard is proposed. Public/ordering routes, workers, event topics,
and other source-only features still need work.

### Why

PL and whitelabel currently boot with 14 marketplace-only deployable-service
routes. Their old apps had none.

### Places to change

- `config/routes.rb`
- `app/controllers/deployable_services_controller.rb`
- `app/controllers/deployable_services/`
- `app/controllers/projects/services/infrastructures_controller.rb`
- `app/jobs/deployable_service/`
- `app/services/deployable_service/`
- `lib/tasks/import.rake`
- `lib/tasks/dev.rake`
- `app/services/jms/manage_message.rb`
- `app/services/ams/process_message.rb`

Gate the whole public route block, not only ESS:

```ruby
if Mp::Variant.marketplace?
  resources :deployable_services, only: %i[index show] do
    # logo and ordering routes stay inside this block
  end
end
```

Also check these source-only features:

- PL catalogue API:
  `../pl-marketplace/app/controllers/api/v1/catalogue/services_controller.rb`
- Whitelabel service unpublish action:
  `../whitelabel-marketplace/app/controllers/backoffice/services/unpublishes_controller.rb`
- PL/whitelabel BOS code:
  `../pl-marketplace/app/services/bos/` and
  `../whitelabel-marketplace/app/services/bos/`

Copy them only when the deployment currently uses them, then add a direct
variant or environment guard.

### Done when

Separate route/task checks show only supported features for each variant.
Disabled features do not read secrets, start workers, enqueue jobs, or make
network calls.

## Task 5 — Finish PL search and API behavior

**Current status: Proposed and waiting for review.** The current proposal adds
the main PL fields and filters. It still needs source comparison, request
coverage, a real Elasticsearch reindex, and API checks.

### Why

The current proposal adds part of PL search, but it has only unit-level checks.
It has not been tested by reindexing and searching copied PL data.

### Merged-repository files

- `app/models/service/search.rb`
- `app/controllers/concerns/service/searchable.rb`
- `app/helpers/service_helper.rb`
- `app/models/filter/research_activity.rb`
- `app/models/vocabulary/research_activity.rb`
- `app/controllers/api/services_controller.rb`
- `app/controllers/api/v1/ess/application_controller.rb`

### Compare with

- `../pl-marketplace/app/models/service/search.rb`
- `../pl-marketplace/app/controllers/concerns/service/searchable.rb`
- `../pl-marketplace/app/helpers/service_helper.rb`
- `../pl-marketplace/app/controllers/api/services_controller.rb`
- `../pl-marketplace/app/controllers/api/v1/catalogue/services_controller.rb`

### Work

- Check tagline, geography, research activities, target users, platforms, and
  any retained related-content fields.
- Make sure old `Vocabulary::ResearchActivity` STI rows load.
- Boot PL, create a new Searchkick index, and reindex a copy of PL data.
- Compare search results, filter counts, and important API responses with the
  old PL app.
- Keep PL fields out of marketplace and whitelabel search documents unless
  those source apps already use them.

### Tests to add or extend

- `spec/models/service/search_spec.rb`
- `spec/controllers/concerns/searchable_spec.rb`
- `spec/requests/services_search_spec.rb`
- `spec/requests/api/services_controller_spec.rb`
- ESS request specs under `spec/requests/api/v1/ess/`

### Done when

The same PL queries and filters return the same records after a full reindex,
and the other variants keep their current search shape.

## Task 6 — Copy the required UI and deployment settings

**Current status: Partial.** A few controller/helper differences are on the
branch. Most PL/whitelabel views, assets, login compatibility, and deployment
defaults are not yet handled.

### Why

Rails boots for all three variants, but PL and whitelabel still need their own
navigation, forms, images, settings, and login configuration.

### Places to compare

- `config/application.rb`
- `config/initializers/devise.rb`
- `app/helpers/application_helper.rb`
- `app/views/layouts/`
- `app/views/backoffice/services/form/`
- `app/views/backoffice/providers/form/`
- `app/assets/`
- the same paths under `../pl-marketplace/`
- the same paths under `../whitelabel-marketplace/`

Important settings to keep:

- the current `SECRET_KEY_BASE` for each deployment;
- all existing Check-in endpoint environment names;
- PL's EOSC Commons URL and recommendation setting;
- whitelabel's HTTPS federation URL;
- the existing STOMP/JMS setting for each deployment;
- monitoring, BOS, import, and external-search settings.

For the first release, use variant-specific partials/assets or the existing
`CUSTOMIZATION_PATH`. Do not build a general theme system yet.

The shared Devise setup should use Rails' resolved secret so environment-based
deployments keep working:

```ruby
config.secret_key = Rails.application.secret_key_base
```

### Done when

A clean build contains all required assets, representative public/backoffice
pages look like the old deployment, and login/callback/logout work without
changing secrets.

## Task 7 — Add small three-variant tests and cut over one app at a time

**Current status: Not started in CI.** Manual separate-process boot checks pass
for all three variants, and an invalid value fails as expected.

### Places to change

- `.github/workflows/ci_backend.yml`
- request/model/service specs listed in Tasks 2–5
- deployment configuration outside this repository

Run each variant in a separate process. Stubbing `Mp::Variant` after Rails
boots does not test routes or initializers.

Minimum checks for each variant:

```text
boot and eager load
expected routes
public page
backoffice page
Service and Provider save/reload
import fixture
JMS fixture
search document and real reindex
manual and remote deletion
```

Use separate database, Redis/cache, and Elasticsearch names in CI.

Cut over one deployment, observe it, then move to the next. The fallback is
the previous application image only if it can use the already-migrated
database. Do not plan a database rollback.

### Done when

All three CI jobs pass, each production deployment reports the expected
variant and shared revision, and the old repositories can no longer deploy.

## Later cleanup — not part of the first release

- Replace direct variant checks with feature/capability configuration.
- Merge duplicate Delete/Destroy services.
- Remove copied compatibility views and services.
- Build a general theme or tenant system.
- Remove old environment aliases.
- Remove legacy database objects after the compatibility period.
- Consider a rake data-cleanup task that moves PL-only satellite/join-table
  data into a shared structure used by all variants.
- Rework serializers.
- Add Discovery Hub or request-time multi-tenancy.
