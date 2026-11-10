# Review of `feat/whitelabel-integration`

Review date: 2026-09-11

## What was reviewed

- Integration branch: `feat/whitelabel-integration` at `5bfa4595`
- Branch starting point: `fda4a92c`
- Current `marketplace/development`: `0ade8e2b`
- `pl-marketplace/development`: `47237a5d`
- `whitelabel-marketplace/development`: `61599be4`
- Documentation in `../arch_docs`
- GitHub issue
  [#3752](https://github.com/cyfronet-fid/marketplace/issues/3752) and its
  current subtasks

The target for the first release is simple: one code repository, three
separate deployments, three separate databases, and one boot variable:

```text
MARKETPLACE_VARIANT=marketplace|pl|whitelabel
```

Temporary branches such as `Mp::Variant.pl?` are expected. Refactoring can
happen after the old repositories stop deploying.

## Short result

All three variant values boot, and an unknown value is rejected. This is a
useful start, but the repository cannot safely replace PL and whitelabel yet.

The main problems are:

1. We do not know exactly which migrations ran on each real database.
2. The committed branch can lose new PL profile values.
3. The shared importers and forms do not handle all PL fields.
4. Delete jobs and JMS messages still use marketplace behavior.
5. PL and whitelabel still expose 14 deployable-service routes.
6. Their UI, login settings, and deployment defaults are not fully copied.

Current status and next steps are in
`docs/repository_consolidation_status.md`.

## What already works

- `lib/mp/variant.rb` exposes `marketplace?`, `pl?`, and `whitelabel?`.
- `config/initializers/variants.rb` rejects an invalid value.
- `config/routes.rb` hides the ESS deployable-service API from PL and
  whitelabel.
- PL profile tables and backfill migrations exist.
- The monitoring credential read no longer crashes when its key is missing.
- JMS publishing now checks `MP_STOMP_PUBLISHER_ENABLED`.
- The branch contains some controller and UI differences found in the source
  repositories.
- The current uncommitted proposal adds PL profile autosave, PL search fields,
  client-credentials import login, and a server-side provider-draft check.
- The focused tests for that proposal passed: 32 examples, 0 failures.

## Problems that block the first release

### 1. Database state is unknown and must be fixed forward

Some consolidation migrations already ran on some applications. They cannot
be rolled back or changed.

The risky files are:

```text
db/migrate/20260429131000_strip_provider_to_v6.rb
db/migrate/20260429141000_strip_service_to_v6.rb
db/migrate/20260429150000_strip_datasource_to_v6.rb
db/migrate/20260909100000_create_service_pl_profiles.rb
db/migrate/20260909100100_create_provider_pl_profiles.rb
db/migrate/20260909100200_backfill_service_pl_profiles.rb
db/migrate/20260909100300_backfill_provider_pl_profiles.rb
db/migrate/20260909100400_remove_pl_legacy_columns_from_services.rb
db/migrate/20260909100500_remove_pl_legacy_columns_from_providers.rb
```

Why this matters: Rails skips a migration when its version is already in
`schema_migrations`, even if the file was later changed. The source file is
therefore not proof of what happened on a real database.

Required action:

- read `schema_migrations` and the real columns from every database;
- compare PL profile rows and values with the old columns or backups; and
- add only new higher-version migrations for repairs.

There is another risk in `config/variants.yml`: a missing variable defaults to
`marketplace`. A migration command aimed at PL could take the marketplace
path. Production should require an explicit value.

Example for a future approved change:

```ruby
if Rails.env.production? && ENV["MARKETPLACE_VARIANT"].blank?
  raise "MARKETPLACE_VARIANT must be set in production"
end
```

### 2. New PL profile values can be lost

Relevant files:

```text
app/models/service.rb
app/models/service/pl_profile.rb
app/models/provider.rb
app/models/provider/pl_profile.rb
```

At committed `HEAD`, setters are delegated to `pl_profile` with
`allow_nil: true`. A new Service or Provider does not have a profile yet, so a
write such as `service.tagline = "..."` can be silently ignored.

The current uncommitted proposal builds the profile for PL and enables
autosave. The important part is:

```ruby
has_one :pl_profile, autosave: true

def pl_profile_for_delegation
  pl_profile || (build_pl_profile if Mp::Variant.pl?)
end
```

This needs tests for Service, Datasource, and Provider create/update/reload.
The tests must also show that other variants do not create PL profiles.

### 3. PL import and backoffice code does not use all PL fields

Merged-repository files:

```text
app/services/importers/service.rb
app/services/importers/provider.rb
app/services/importers/datasource.rb
app/policies/backoffice/service_policy.rb
app/policies/backoffice/provider_policy.rb
app/views/backoffice/services/form/
app/views/backoffice/providers/form/
```

Full PL behavior is still available here:

```text
../pl-marketplace/app/services/importers/service.rb
../pl-marketplace/app/services/importers/provider.rb
../pl-marketplace/app/services/importers/datasource.rb
../pl-marketplace/app/policies/backoffice/service_policy.rb
../pl-marketplace/app/policies/backoffice/provider_policy.rb
../pl-marketplace/app/views/backoffice/services/form/
../pl-marketplace/app/views/backoffice/providers/form/
```

The PL importer handles tagline, contacts, research activities, target users,
geography, URLs, related services, platforms, certifications, and datasource
policy fields. The shared importer handles only the smaller V6 set. Old data
may survive the backfill, but the next import can leave it stale or blank.

For the first release, a direct condition is enough:

```ruby
attributes.merge!(pl_attributes) if Mp::Variant.pl?
```

Copy the complete PL mapping. Do not treat the short example as the field
list.

PL model behavior also needs to be copied from:

```text
../pl-marketplace/app/models/service.rb
../pl-marketplace/app/models/provider.rb
```

This includes URL/email validation, required fields, array cleanup, country
conversion, and the `horizontal` scope.

### 4. Delete behavior is different and has not been copied

Current merged-repository files:

```text
app/services/service/pc_delete.rb
app/services/service/destroy.rb
app/services/offer/delete.rb
app/services/offer/destroy.rb
app/services/provider/delete.rb
app/services/catalogue/delete.rb
app/jobs/service/delete_job.rb
app/jobs/provider/delete_job.rb
app/controllers/backoffice/services_controller.rb
app/controllers/services/ordering_configuration/offers_controller.rb
app/controllers/api/v1/resources/offers_controller.rb
```

PL and whitelabel behavior is in:

```text
../pl-marketplace/app/services/service/delete.rb
../pl-marketplace/app/services/service/pc_delete.rb
../pl-marketplace/app/services/provider/delete.rb
../pl-marketplace/app/services/provider/pc_delete.rb
../pl-marketplace/app/jobs/delete_job.rb
../whitelabel-marketplace/app/services/service/delete.rb
../whitelabel-marketplace/app/services/service/pc_delete.rb
../whitelabel-marketplace/app/jobs/delete_job.rb
```

PL and whitelabel cascade some deletes to Services, Offers, and Bundles. The
marketplace path has different rules. A remote PL provider deletion currently
uses marketplace code and can leave the provider active when it still has
services.

Keep both implementations for now and choose by variant:

```ruby
operation = Mp::Variant.marketplace? ? Service::Destroy : Service::Delete
operation.call(@service)
```

The same approach is needed for `Offer::Destroy` and `Offer::Delete`.
Explanatory comments now exist in those two files so this temporary split is
not removed as cleanup.

### 5. PL and whitelabel JMS messages may fail before creating a job

Current code:

```text
app/services/jms/manage_message.rb
```

Source code:

```text
../pl-marketplace/app/services/jms/manage_message.rb
../whitelabel-marketplace/app/services/jms/manage_message.rb
```

PL and whitelabel can put JSON text inside `body["resource"]`. Current merged
code expects a Hash. Accept both formats:

```ruby
event_body = body["resource"] || body
event_body = JSON.parse(event_body) if event_body.is_a?(String)
```

Tests should use saved service, provider, catalogue, datasource, and delete
messages from all three applications.

### 6. Marketplace-only routes are still active in other variants

The ESS route is already guarded near the bottom of `config/routes.rb`, but the
public `resources :deployable_services` block near the top is not guarded.

A separate Rails process reported:

```text
marketplace: 16 deployable-service routes
pl:          14 deployable-service routes
whitelabel:  14 deployable-service routes
```

The old PL and whitelabel applications have none of these routes. The whole
route block should be inside the marketplace condition:

```ruby
if Mp::Variant.marketplace?
  resources :deployable_services, only: %i[index show] do
    # logo and ordering routes
  end
end
```

Related places:

```text
app/jobs/deployable_service/
app/services/deployable_service/
app/controllers/projects/services/infrastructures_controller.rb
lib/tasks/import.rake
lib/tasks/dev.rake
app/services/jms/manage_message.rb
app/services/ams/manage_message.rb
```

### 7. UI and deployment settings are still different

Compared with the merged working tree, PL has 71 files under `app`, `lib`, and
`config` that are absent. Whitelabel has 69. Some are alternate images or
views, but the list also includes forms, jobs, policies, serializers, and BOS
code.

Start comparison here:

```text
config/application.rb
config/initializers/devise.rb
app/helpers/application_helper.rb
app/views/layouts/
app/views/backoffice/services/form/
app/views/backoffice/providers/form/
app/assets/
```

Compare the same paths under `../pl-marketplace/` and
`../whitelabel-marketplace/`.

Important differences:

- PL and whitelabel used the old `whitelabel` flag as true. The new PL variant
  returns false, which changes navigation and favourites.
- PL uses a different EOSC Commons URL and disables recommendations by
  default.
- Whitelabel uses HTTPS for the federation API default; merged code uses HTTP.
- STOMP/JMS defaults differ.
- Check-in endpoint environment variable names differ.
- Devise currently reads `credentials.secret_key_base` directly. Existing
  containers may provide only `SECRET_KEY_BASE`.

For the shared Devise setup, the safe shape is:

```ruby
config.secret_key = Rails.application.secret_key_base
```

The actual secret value must not change during cutover.

For the first release, copied variant partials/assets or the existing
`CUSTOMIZATION_PATH` are enough. A general theme system can wait.

## Other items to check before cutover

### Search

The current proposal changes:

```text
app/models/service/search.rb
app/controllers/concerns/service/searchable.rb
app/helpers/service_helper.rb
app/models/filter/research_activity.rb
app/models/vocabulary/research_activity.rb
```

Compare these with the same files in `../pl-marketplace/`. Then build a real
PL Searchkick index and test the filters with copied PL data. The current unit
tests do not prove that Elasticsearch mappings and aggregation counts work.

### Provider “Save as draft”

Relevant files:

```text
app/controllers/backoffice/providers/steps_controller.rb
app/services/provider/draft.rb
app/views/backoffice/providers/steps/_buttons.html.haml
../whitelabel-marketplace/app/services/provider/create_as_draft.rb
```

The proposed server-side variant check is useful. The current merged action
still differs from whitelabel because the source reindexes and redirects to
the provider page. Decide whether this visible difference is acceptable, then
test the chosen result.

### Branch update

Current `development` is three commits ahead of the integration branch's
starting point, but the only file changes are `CHANGELOG.md` and `version.txt`.
This is not an application blocker.

## Test gap

The committed branch does not run the full application as all three variants.
Tests that stub `Mp::Variant.pl?` after Rails starts cannot check routes,
initializers, or Searchkick boot settings.

Add three separate CI jobs in:

```text
.github/workflows/ci_backend.yml
```

Each job should set one variant and use separate database, Redis, and
Elasticsearch names. At minimum test boot, routes, one public page, one
backoffice page, PL profile persistence, an import fixture, a JMS fixture,
search, and deletion.

## Current uncommitted proposal

These changes still need developer review before commit:

| Change | State |
|---|---|
| PL profile build/autosave | Basic create/reload tests pass; full field coverage is missing |
| PL country conversion | Focused tests pass |
| PL search and filters | Unit tests pass; real reindex test is missing |
| Client-credentials import token | Focused tests pass; deployment variables need confirmation |
| Provider draft server check | Focused request tests pass; source redirect/reindex differs |
| Offer compatibility comments | Added as requested |
| Review and task Markdown | Local only; no external issues created |

No database rollback, destructive database command, commit, or push was run
during this review.

