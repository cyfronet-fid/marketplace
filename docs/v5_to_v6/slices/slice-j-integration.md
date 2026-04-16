# Slice J: Integration, cleanup, deploy (2.5d)

By now, most specs are fixed incrementally (each slice fixed its own). What remains is cross-cutting cleanup and final verification.

**Depends on Slices A–H (and I if in scope):** every model / migration / importer / serializer / topic rename must already be merged. Slice J only removes dead weight and validates the end state; it does not introduce new V6 behaviour.

**References Slice 0 decisions:** D1 (Catalogue deferral if applicable), D5 (Slice I topics), D6 (tag cleanup), D9 (PID system models deleted), D19 (data_administrators kept but no longer imported).

---

## J1. Fix remaining controller/feature specs (1d)

### Controller specs

- `spec/controllers/backoffice/providers_controller_spec.rb` — remove tests for deleted wizard steps (`location`, `contacts`, `maturity`, `network`, `classification`, `services`). Keep `basic`, `managers`, `summary`.
- `spec/controllers/backoffice/services_controller_spec.rb` — remove assertions for deleted form sections (`geographic_availability`, `platforms`, `target_users`, `marketplace_locations`, `life_cycle_status`, `funding`, `dedicated_for`, `classification` target users + marketplace locations).
- `spec/controllers/backoffice/datasources_controller_spec.rb` — remove PID system form fields (Slice D deleted the `persistent_identity_systems` table and its model).
- `spec/controllers/backoffice/deployable_services_controller_spec.rb` — verify V6 fields pass through (Slice E kept the shape but renamed inbound topics).
- `spec/controllers/api/v1/...` — update `expected_response` hashes to remove dropped attributes.

### Request specs (rswag — generate OpenAPI)

- Update `spec/requests/api/v1/services_spec.rb`, `providers_spec.rb`, `datasources_spec.rb`, `deployable_services_spec.rb`, `guidelines_spec.rb` — remove dropped fields from request/response schemas.
- If Slice I shipped: add `spec/requests/api/v1/adapters_spec.rb`, `training_resources_spec.rb` (show-only endpoints).
- Regenerate docs: `./bin/rails rswag`.
- Verify `swagger/v1/swagger.yaml` no longer lists removed fields.

### Feature specs (Capybara)

- `spec/features/backoffice/create_provider_spec.rb` — simplified wizard (basic → managers → summary).
- `spec/features/backoffice/create_service_spec.rb` — fewer form sections; assertions against `access_types`, `nodes`, `alternative_pids`, `public_contact_emails`, `urls`.
- `spec/features/search_*_spec.rb` — remove expectations about filters for `target_users`, `marketplace_locations`, `geographical_availabilities`, `platforms`, `dedicated_for`, `structure_types`, `networks`, `esfri_domains`, `esfri_types`, `areas_of_activity`, `societal_grand_challenges`, `meril_scientific_domains`, `life_cycle_status`, `funding_body`, `funding_program` (Slice C removed these facets).

### Validate

```bash
bundle exec rspec spec/controllers/ spec/requests/ --format progress
# Should pass with 0 failures.

bundle exec rspec spec/features/backoffice/ spec/features/search_*_spec.rb --format progress
# Should pass with 0 failures.

# rswag regen produces clean diff:
./bin/rails rswag
git diff --stat swagger/
```

---

## J2. Integration test against PC (0.5d)

Full import run against PC dev/integration instance, verifying the end-to-end pipeline.

### Endpoints

- Dev: `https://dev.providers.sandbox.eosc-beyond.eu/api`
- Integration: `https://integration.providers.sandbox.eosc-beyond.eu/api`

### Test checklist (Slice-aligned)

Batch imports (Slice D18 suffixes — no `/all`):

- [ ] `bundle exec rake import:vocabularies` — 12 vocabs (A4) or 22 (if Slice I shipped).
- [ ] `bundle exec rake import:providers` — target endpoint: `public/organisation` (V6; Slice B6 replaces V5's `public/provider/bundle`).
- [ ] `bundle exec rake import:resources` — target endpoint: `public/service` (V6; Slice C6 replaces V5's `public/resource/bundle`).
- [ ] `bundle exec rake import:datasources` — target endpoint: `public/datasource`.
- [ ] `bundle exec rake import:deployable_services` — target endpoint: `public/deployableApplication`.
- [ ] `bundle exec rake import:guidelines` — target endpoint: `public/interoperabilityRecord`. Connections import hits `public/resourceInteroperabilityRecord` (Slice H6).
- [ ] If Slice I: `bundle exec rake import:adapters`, `bundle exec rake import:training_resources`.
- [ ] Slice F deferral: skip `rake import:catalogues` — still runs V5 path, not touched here.

JMS / AMS (Slice G):

- [ ] Publish a fake `eosc.organisation.update` message with `spec/fixtures/stomp/provider_update.json` — verify `Provider::PcCreateOrUpdateJob` enqueues.
- [ ] Publish `eosc.deployable_application.create` — `DeployableService::PcCreateOrUpdateJob`.
- [ ] Publish `eosc.interoperability_record.update` — `Guideline::PcCreateOrUpdateJob` (routed via `INBOUND_TOPIC_ALIASES`).
- [ ] Legacy `eosc.provider.update` still routes (dual-key fallback body parse — G1).
- [ ] AMS: `mp-organisation-update` → same job chain.
- [ ] If Slice I: `mp-adapter-update`, `mp-training_resource-create`.

Data integrity probes:

- [ ] `Provider.where.not(pid: nil).count` matches imported count.
- [ ] `ProviderAlternativeIdentifier.count > 0` — D14 alternative_pids populated.
- [ ] `Provider.pluck(:public_contact_emails).flatten.compact.any?` — D17 extractor produced emails.
- [ ] `Service.distinct.pluck(:status).sort == %w[draft published]` — no orphan statuses.
- [ ] `Datasource.unscoped.count == Service.where(type: "Datasource").count` — STI intact (D11).
- [ ] `Vocabulary.distinct.pluck(:type).sort` matches Slice A4 keep-list (9 types, or 19 if Slice I shipped).
- [ ] Non-public ID handling: no DB row has `pid` ending in `"00"` (MP consumes only public endpoints; confirm via `grep '00$' pid`).

ESS sync (Propagable → Ess::Add):

- [ ] Save a Provider in a Rails console → tail sidekiq log → `Ess::Add` enqueues → serialized JSON contains ONLY V6 fields listed in `ess/provider_serializer.rb`.
- [ ] Same for Service, Datasource, DeployableService, Guideline.

Logo pipeline (`Importers::Logo`):

- [ ] One provider from the import has an attached logo (Active Storage blob exists).
- [ ] One with missing `logo` URL did NOT error (graceful skip).

### Validate

```bash
MP_IMPORT_EOSC_REGISTRY_URL=https://integration.providers.sandbox.eosc-beyond.eu/api \
  DRY_RUN=true bundle exec rake import:providers import:resources import:datasources \
                                    import:deployable_services import:guidelines
# Each task should print "PROCESSED: N, CREATED: 0, UPDATED: 0" (dry-run) with no NameError / 404 / NoMethodError.

# JMS dry:
docker compose up -d activemq
bundle exec rails runner '
  require "stomp"
  c = Stomp::Client.open("stomp://admin:admin@localhost:61613")
  %w[organisation deployable_application interoperability_record service].each do |rt|
    c.publish("/topic/eosc.#{rt}.update",
              File.read("spec/fixtures/stomp/#{rt == "organisation" ? "provider" : rt}_update.json"),
              { persistent: true })
  end
  sleep 2
'
# Sidekiq log should show one job enqueued per topic (Provider::, DeployableService::, Guideline::, Service::).
```

---

## J3. Cleanup sweep (0.5d)

This is the dead-code pass. Every reference below points to something that Slices A–I already _should_ have removed but often leaves behind because it's in a helper, partial, or seed file outside the model/controller hot path.

### Model / code deletion roll-up (verify, do NOT re-delete)

Slices A–I should already have deleted these files. Run `ls` on each — every one should be missing. If any still exist, delete them here:

**From Slice A (vocabularies + links):**

```
app/models/vocabulary/{access_mode,area_of_activity,entity_type,entity_type_scheme,esfri_domain,esfri_type,funding_body,funding_program,life_cycle_status,marketplace_location,meril_scientific_domain,network,provider_life_cycle_status,research_product_access_policy,research_product_metadata_access_policy,service_category,societal_grand_challenge,structure_type}.rb
app/models/platform.rb
app/models/service_relationship.rb
app/models/required_service_relationship.rb
app/models/manual_service_relationship.rb
app/models/link/use_cases_url.rb
app/models/link/research_product_license_url.rb
app/models/link/research_product_metadata_license_url.rb
```

**From Slice C (Service):** no model files deleted; only fields/associations.

**From Slice D (Datasource / PID system — per D9):**

```
app/models/persistent_identity_system.rb
app/models/persistent_identity_system_vocabulary.rb
```

(The `persistent_identity_systems` and `persistent_identity_system_vocabularies` tables are dropped in Slice D1. No V6 code references either — if you find any, it's dead and should be deleted here.)

**From Slice F (Catalogue — DEFERRED per D1):**

- `MainContact`, `PublicContact`, `Contact` classes STAY. They're still needed because Catalogue uses them (Slice F did not ship). **Do not delete.** When Slice F lands in a follow-up PR, its own cleanup removes them.

**From Slice I (only if NOT shipped):**

- `TargetUser` kept per D8 specifically for Slice I. If Slice I is permanently deferred, delete `app/models/target_user.rb`, `app/models/vocabulary/target_user.rb` (if exists), `spec/factories/target_users.rb`, and drop `target_user` from `VOCABULARY_TYPES`, `TARGET_USER` from `ACCEPTED_VOCABULARIES`. Coordinate this with the product decision — document in the PR description.

### Orphan policies / controllers

```
app/policies/backoffice/platform_policy.rb            # Platform deleted in A
app/policies/backoffice/target_user_policy.rb         # only delete if TargetUser deleted above
app/policies/backoffice/persistent_identity_system_policy.rb  # model deleted in D
```

Search:

```bash
grep -rln "Backoffice::PlatformPolicy\|Backoffice::TargetUserPolicy\|Backoffice::PersistentIdentitySystemPolicy" app/
# Any surviving references must be deleted or updated.
```

### Dead-code patterns (run each `rg` and address every hit)

```bash
# Removed models / classes — zero hits expected in app/ + lib/ (spec/ may still have deletion-candidate specs):
rg -n --glob '!docs/**' --glob '!spec/**' \
  "\bPlatform\b|\bManualServiceRelationship\b|\bRequiredServiceRelationship\b|\bServiceRelationship\b|\bPersistentIdentitySystem\b|\bPersistentIdentitySystemVocabulary\b|Link::UseCasesUrl|Link::ResearchProductLicenseUrl|Link::ResearchProductMetadataLicenseUrl" \
  app/ lib/ config/

# Removed vocabularies:
rg -n --glob '!docs/**' --glob '!spec/**' \
  "Vocabulary::AccessMode|Vocabulary::AreaOfActivity|Vocabulary::EntityType\b|Vocabulary::EntityTypeScheme|Vocabulary::EsfriDomain|Vocabulary::EsfriType|Vocabulary::FundingBody|Vocabulary::FundingProgram|Vocabulary::LifeCycleStatus|Vocabulary::MarketplaceLocation|Vocabulary::MerilScientific|Vocabulary::Network\b|Vocabulary::ProviderLifeCycleStatus|Vocabulary::ResearchProductAccessPolicy|Vocabulary::ResearchProductMetadataAccessPolicy|Vocabulary::ServiceCategory|Vocabulary::SocietalGrandChallenge|Vocabulary::StructureType" \
  app/ lib/ config/

# Removed Provider / Service fields:
rg -n "\b(street_name_and_number|postal_code|hosting_legal_entity_string|participating_countries|affiliations|national_roadmaps|certifications|tagline|target_users|platforms|marketplace_locations|geographical_availabilities|dedicated_for|related_platforms|life_cycle_status|funding_body|funding_program|access_mode|life_cycle_statuses)\b" \
  app/ lib/ config/ --glob '!docs/**' --glob '!spec/**'

# Removed Datasource PID system fields (D9):
rg -n "entityType|entityTypeScheme|productAccessPolicy|metadataLicense|persistent_identity_system" \
  app/ lib/ config/ --glob '!docs/**' --glob '!spec/**'

# V5 outbound topic names (Slice G7):
rg -n "(provider|deployable_software)\.(create|update|delete)" app/ config/
```

Every hit must be either (a) dead code to delete, (b) a V6 rename that was missed, or (c) a legitimate comment documenting the V5→V6 migration (OK to keep but rare).

### Helpers / i18n / partials

```bash
# View partials referencing deleted form sections:
ls app/views/backoffice/providers/_{location,contacts,maturity,network,classification,services}.html.haml 2>&1 | grep -v "No such"
# Every listed file is dead — delete.

ls app/views/backoffice/services/_{geographic_availability,platforms,target_users,marketplace_locations,dedicated_for,life_cycle_status,funding,related_platforms}.html.haml 2>&1 | grep -v "No such"
# Every listed file is dead — delete.

# i18n keys for removed fields:
rg -n "street_name_and_number:|participating_countries:|affiliations:|national_roadmaps:|tagline:|target_users:|platforms:|marketplace_locations:|geographical_availabilities:|dedicated_for:|life_cycle_status:|funding_body:|funding_program:|certifications:" config/locales/
# Delete matching lines in config/locales/en/*.yml and config/locales/pl/*.yml.
```

### Seed data

- `db/data.yml` — remove all entries for deleted fields (used by `rake dev:prime` → `CreateAllFromPath`). Grep for the same field list from J3 dead-code patterns.
- `db/data_e2e.yml` — same (used by Cypress E2E tests — `test/system/cypress/e2e/`).

After edit, run:

```bash
bundle exec rake dev:prime
# Must complete without raising — any "unknown attribute" error means a field was missed.
```

### Rake tasks

- `lib/tasks/import.rake` — verify every task has the V6 suffix (no `/all`), matches Slice B/C/D/E/H/I orchestrators.
- `lib/tasks/dev.rake` (`dev:prime`) — `create_all_from_path` works with V6 schema (implicitly validated by seed-file edit above).
- `bundle exec rake searchkick:reindex:all` — executes without NoMethodError (Service::Search#search_data rewritten in Slice C).

### Cypress E2E specs (dev-host only)

Files present in repo:

```
test/system/cypress/e2e/provider_portal/provider_catalogue.spec.ts
test/system/cypress/e2e/provider_portal/provider_approved.spec.ts
test/system/cypress/e2e/provider_portal/provider_rejected.spec.ts
test/system/cypress/e2e/provider_portal/resource_catalogue.spec.ts
test/system/cypress/e2e/provider_portal/resource_approved.spec.ts
test/system/cypress/e2e/provider_portal/resource_rejected.spec.ts
```

For each file:

- Replace selectors for deleted fields (same list as J3 dead-code patterns) with V6 equivalents or delete the assertion.
- For wizard specs: remove step navigations to deleted steps (`location`, `contacts`, `maturity`, `network`, `classification`, `services`).
- Confirm `db/data_e2e.yml` edits above still let the fixture build.

Run locally:

```bash
cd test/system/cypress && npm run cypress:run -- --spec "e2e/provider_portal/*.spec.ts"
```

### Propagable concern + ESS sync

Re-grep to confirm no removed field still appears in an `Ess::*Serializer`:

```bash
rg -n "(participating_countries|affiliations|target_users|platforms|marketplace_locations|funding_body|esfri_domain|structure_type|main_contact|public_contacts\b)" app/serializers/ess/
# Should return 0
```

### Federation controllers

- `app/controllers/federation/services_controller.rb` — per **D22**, default is KEEP the federation serializer emitting removed fields as `nil` / `[]` for one deprecation cycle. Do NOT drop them from the JSON response in this PR unless D22 resolves to an explicit consumer sign-off. File a follow-up issue to remove them after one cycle.

### `Jms::ManageMessage` — INBOUND_TOPIC_ALIASES removal (deferred milestone)

Slice G1 added:

```ruby
INBOUND_TOPIC_ALIASES = {
  "organisation" => "provider",
  "deployable_application" => "deployable_service",
  "interoperability_record" => "guideline"
}.freeze
```

and the dual-body-key parse (`body[raw_type.camelize(:lower)] || body[resource_type.camelize(:lower)]`).

**Do NOT remove either in this migration PR.** They are the cutover bridge. Track removal in a follow-up issue; the trigger is Athena confirming no V5 messages flow to production for >2 weeks. Add one comment at the top of both `jms/manage_message.rb` and `ams/manage_message.rb`:

```ruby
# TODO(post-V6-cutover): remove INBOUND_TOPIC_ALIASES + dual-key body parse — see issue #XXXX
```

### `data_administrators` consistency audit (D19)

Per D19, importers no longer populate `data_administrators`. In Slice B5 and Slice F3 (deferred) the line `data_administrators: Array(@data["users"]).map { |u| map_data_administrator(u) }` was removed. Verify:

```bash
rg -n "data_administrators:" app/services/importers/
# Should return 0 (importers do NOT touch the column).

rg -n "data_administrators" app/models/provider.rb app/models/catalogue.rb
# Should still show the has_many + accepts_nested_attributes (model-level, kept).
```

The `provider.managers` partial (Slice B9) must mention the operator workflow:

> "Data administrators are no longer auto-populated from the PC. Add them manually using the search below."

Grep to confirm the line is in the view:

```bash
grep -n "no longer auto-populated" app/views/backoffice/providers/_managers.html.haml
```

---

## J4. Staging deploy + smoke test (0.5d)

### Pre-deploy checklist

- [ ] DB backup taken: `pg_dump $STAGING_DATABASE_URL > tmp/pre_v6_staging_YYYYMMDD.sql`.
- [ ] If D3 ARCHIVE was set: confirm `tmp/v5_archive_YYYYMMDD.json` exists (from Slice B runbook).
- [ ] `git log --oneline origin/master..HEAD` — every slice commit present, in order A → B → … → (I?) → J.

### Deploy steps (ordered)

1. **Run migrations on staging DB** (`rails db:migrate RAILS_ENV=staging`):
   - Slice A6 drops V5 vocab rows + `service_target_users` / `service_related_platforms` / `service_relationships` / `platforms` tables.
   - Slice B1 backfills `providers.public_contact_emails` from `contacts`.
   - Slice B2 strips provider columns.
   - Slice C2 strips services columns.
   - Slice D1 drops `persistent_identity_systems` + `persistent_identity_system_vocabularies` tables.
   - Slice E1 adds `urls` + simplifies `deployable_services`.
   - Slice H1 adds guideline columns + `guideline_sources` + `guideline_alternative_identifiers`.
   - (If Slice I:) create `adapters`, `adapter_sources`, `adapter_alternative_identifiers`, `training_resources`, `training_resource_*`.
2. **Run full vocabulary import:** `rake import:vocabularies` (12 keys, or 22 if Slice I shipped).
3. **Run batch imports in dependency order:** providers → resources → datasources → deployable_services → guidelines → (adapters → training_resources if Slice I).
4. **Elasticsearch reindex:** `rake searchkick:reindex:all` — must complete.
5. **ESS dump (SOLR):** `rake ess:reindex:all` — verifies every `Ess::*Serializer` produces valid JSON.

### Smoke tests

- [ ] Backoffice forms: create + edit a Provider (simplified wizard — basic/managers/summary only), create + edit a Service.
- [ ] Public show pages render for: Service, Provider, Datasource, DeployableService, Guideline.
- [ ] Search pages: service facets work for surviving filters (scientific_domain, node, access_type, trl, jurisdiction, categories). NO "target_users" / "platforms" / "marketplace_locations" / "geographical_availabilities" facets visible.
- [ ] JMS subscriber connects and processes one real message from PC staging.
- [ ] `log/sidekiq.log` shows `Provider::PcCreateOrUpdateJob` / `Service::PcCreateOrUpdateJob` runs without stack traces.
- [ ] `Provider.count > 0 && Service.count > 0 && Guideline.count > 0`.
- [ ] Random sample of 5 rows per entity: all required fields populated; no NULL `public_contact_emails` where PC provided contacts.
- [ ] N+1 check (optional): run `PROSOPITE=1` or `BULLET=1` across the golden-path page loads; no new N+1 reported against Slices B–H touched code.

### Rollback plan

- DB restore from `tmp/pre_v6_staging_YYYYMMDD.sql`.
- Git revert merge commit of the migration PR.
- Manual step: re-subscribe AMS to V5 topic names (`mp-provider-*`, `mp-deployable_service-*`) — coordinate with Athena; V5 topics may have stopped emitting.

### Validate (full suite)

```bash
bundle exec rspec --format progress
# Full test suite should pass with 0 failures.

rubocop
# No new offenses (existing baseline unchanged).

haml-lint --exclude 'lib/**/*.haml'
# No new offenses.

# Final orphan-reference check:
rg -n --glob '!docs/**' --glob '!spec/**' \
  "\bPlatform\b|\bPersistentIdentitySystem\b|ServiceRelationship|Vocabulary::AccessMode|Vocabulary::FundingBody|Vocabulary::LifeCycleStatus|Vocabulary::Network\b|Vocabulary::StructureType|Vocabulary::EsfriDomain|Vocabulary::MerilScientific" \
  app/ lib/ config/
# Should return 0.

# V5 outbound topic names:
rg -nE "(provider|deployable_software)\.(create|update|delete)" app/ config/
# Should return 0.

# Migration idempotency — re-running must be no-op:
bundle exec rails db:migrate:status | grep -v "up"
# Should return 0 (every migration "up").
```

---

## J5. PR description + open-questions closeout

Update `docs/v5_to_v6/README.md`:

- [ ] Check every decision D1–D19 as resolved (or D1 marked "deferred to follow-up PR").
- [ ] Check every slice box A–H (and I if shipped).
- [ ] Link the staging deploy run in the PR description.

PR description template:

```
## Summary
V5 → V6 PC API migration, slices A–{H|I}. Catalogue (Slice F) {deferred per D1 | included}.

## Changes
- {slice-by-slice bullets pulled from each commit}

## Test plan
- [ ] `bundle exec rspec` green
- [ ] Staging deploy + smoke tests (see J4)
- [ ] Dry-run imports against dev + integration endpoints

## Rollback
See slice-j-integration.md §J4 "Rollback plan".

## Deferred / follow-up
- Slice F (Catalogue) — {status per D1}
- INBOUND_TOPIC_ALIASES removal — tracked in issue #XXXX (trigger: V5 message flow stops >2 weeks)
- {Slice I if deferred}
```

**Commit J.** Full suite green on CI, staging healthy, PR ready for review.

---

## Out of scope (explicit)

- Renaming Rails classes `Provider` → `Organisation` / `DeployableService` → `DeployableApplication` — not this migration.
- Removing `INBOUND_TOPIC_ALIASES` and V5 body-key fallback — post-cutover follow-up.
- Catalogue V6 schema (Slice F) — deferred per D1.
- Federation consumer coordination — ops/product task outside this PR.
- STOMP broker credential rotation (Slice G4) — ops ticket, tracked separately.
