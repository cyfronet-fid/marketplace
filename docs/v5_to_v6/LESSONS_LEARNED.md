# V5 to V6 Lessons Learned

## Slice J: Integration cleanup

Implemented partially on 2026-04-30. Full local/live validation moved to Slice K.

### What changed

- Rails feature specs, request schemas, generated swagger component schemas, seeds, Cypress fixtures, Cypress support helpers, and Cypress specs were cleaned up for the V6 Provider/Service/Datasource surface.
- Backoffice Service edit no longer renders deleted `Service#restrictions` or `Service#activate_message`, which had been a real 500-risk after Slice C removed those columns.
- Homepage no longer loads or renders removed Service filter cards for `related_platforms` and `dedicated_for`.
- Cypress specs now use negative assertions for removed filters/fields instead of trying to exercise V5-only UI.
- The Provider/Service/Datasource ESS component schemas were manually aligned after `./bin/rails rswag`, because rswag regenerates the top-level OpenAPI files but does not fully rewrite those checked-in component schema files.
- Catalogue, Bundle target users, Adapter/TrainingResource, and JMS/AMS alias compatibility were preserved as explicit exceptions.

### What to watch out for

- `localhost:5000` may be owned by macOS AirPlay/AirTunes and return `403 Forbidden` with `Server: AirTunes/935.7.1`. Cypress and browser QA are invalid until Rails is actually serving the selected port.
- Removing V5 seed keys mechanically can still leave YAML anchors behind. In this pass, `restrictions: &notSpecified` remains only as an anchor source for existing aliases; active Service restriction data was removed.
- Search/filter specs now use "Organisations" as the user-facing provider filter label. Old "Providers:" expectations are stale.
- RuboCop and haml-lint can fail in the sandbox because they try to write under `~/.cache/rubocop_cache`. Use a writable `RUBOCOP_CACHE_ROOT` when needed.
- `./bin/rails rswag` may need sandbox escalation if the local DB socket/connection is blocked by the sandbox.
- Do not treat remaining Catalogue structured-contact/location/network/schema hits as Slice J cleanup targets; they are the Slice F exception.

### Validation run

- `./bin/rails rswag` (331 examples, 0 failures, 1 pending in docs generation)
- `bundle exec rspec spec/features/backoffice/services_spec.rb:112 spec/features/backoffice/services_spec.rb:129 spec/features/search_spec.rb:182 spec/features/filter_spec.rb spec/features/comparison_spec.rb spec/features/service_question_spec.rb spec/services/service/pc_create_or_update_spec.rb spec/requests/api/v1/ess/services_controller_spec.rb spec/requests/api/v1/ess/providers_controller_spec.rb spec/requests/api/v1/ess/datasources_controller_spec.rb spec/requests/api/v1/search/services_controller_spec.rb` (64 examples, 0 failures, 3 pending)
- `ruby -e 'require "yaml"; %w[db/data.yml db/data_e2e.yml].each { |f| YAML.load_file(f, aliases: true); puts "#{f} ok" }'`
- `git diff --check`
- Targeted `rubocop` on touched Ruby/spec files with writable `RUBOCOP_CACHE_ROOT`
- Targeted `haml-lint` on touched HAML files with writable `RUBOCOP_CACHE_ROOT`
- `cd test/system && yarn install`

### Blocked validation

- `npm run cy:run -- --spec "cypress/e2e/**/*.spec.ts"` started but failed immediately because `http://localhost:5000/` was not Rails.
- Full `bundle exec rspec`, full `rubocop`, full `haml-lint`, Searchkick reindex, ESS reindex, fresh/current DB import gates, live browser screenshots, and external contract sweep are tracked in `docs/v5_to_v6/slices/slice-k-validation-closeout.md`.

## Slice I: New entity types

Checked on 2026-04-30.

### What changed

- No code changes were made. Adapter and TrainingResource remain explicitly out of scope for Marketplace sync per D5/D24.
- The implementation details in `docs/v5_to_v6/slices/slice-i-new-entities.md` are archival research only; the authoritative current contract is the no-op section at the top of that file.
- No Adapter or TrainingResource models, tables, importers, jobs, routes, ESS serializers, UI, search indexes, JMS/AMS branches, or subscriptions were added.
- Adapter/TR-only vocabularies were not added to `ACCEPTED_VOCABULARIES` or `VOCABULARY_TYPES`.
- Existing JMS/AMS specs assert out-of-scope adapter messages are unsupported rather than silently routed.

### What to watch out for

- Do not copy the archived Adapter/TR field lists into code unless Product reopens scope and live V6 endpoints are re-verified first.
- Do not keep or add `TargetUser` solely for TrainingResource; TrainingResource sync is out of scope.
- Greps for "adapter" are noisy because the repo also has OMS adapter docs, Faraday adapters, ActionCable adapters, and ActiveJob queue adapters. Treat only Provider Catalogue Adapter entity hooks as relevant.
- Slice G should continue to route only in-scope V6 topics. Adapter/TR JMS or AMS subscriptions should not be added in this migration.

### Validation run

- `rg -n "adapter|trainingResource|training_resource|TrainingResource|Adapter|TR_ACCESS_RIGHT|TR_CONTENT_RESOURCE_TYPE|TR_DCMI_TYPE|TR_EXPERTISE_LEVEL|TR_QUALIFICATION|ADAPTER_PROGRAMMING_LANGUAGE|SPDX_LICENSE|SQA_BADGE|CREDIT" app config lib spec docs/v5_to_v6/LESSONS_LEARNED.md`
- `rg -n "ACCEPTED_VOCABULARIES|ADAPTER|TR_|SPDX|SQA|CREDIT|LANGUAGE|TARGET_USER" lib/import/vocabularies.rb config/initializers/constants.rb app/models/vocabulary`
- Manual check of `config/ams_subscriber.yml` confirmed no Adapter/TR topics.

## Slice H Lite: Guideline compatibility

Implemented on 2026-04-30.

### What changed

- Guideline import now maps V6 `InteroperabilityGuideline.name` into the existing `guidelines.title` column.
- Legacy `title` payloads are still accepted as a fallback for older fixtures/messages.
- JMS/AMS guideline event sync uses the same `name.presence || title` mapping through `Guideline::PcCreateOrUpdate`.
- Service-guideline linking still uses the existing `service_guidelines` join table and `/public/resourceInteroperabilityRecord` connection feed.
- The linker now queries `Guideline.where(eid: guideline_eids)` instead of wrapping the array again, so multiple linked guideline IDs resolve correctly.
- No new InteroperabilityGuideline table, rich metadata storage, ESS shape, or UI path was added.

### What to watch out for

- Slice G already routes V6 `interoperability_record.*` messages to existing Guideline jobs. H Lite only needed to fix the payload field consumed by those jobs.
- `guidelines.title` is nullable, so missing `name` mapping can silently create blank labels instead of raising an import error.
- Keep rich V6 interoperability metadata deferred unless a concrete Marketplace consumer needs it.
- The pre-commit Prettier hook checks Markdown and Ruby specs. Run `bin/bundle exec rbprettier --write docs/v5_to_v6/slices/slice-h-lite-guideline.md spec/lib/import/guidelines_spec.rb` if the hook reports formatting drift.

### Validation run

- `bundle exec rspec spec/lib/import/guidelines_spec.rb spec/services/guideline/pc_create_or_update_spec.rb`
- `bundle exec rubocop lib/import/guidelines.rb app/services/guideline/pc_create_or_update.rb spec/lib/import/guidelines_spec.rb spec/services/guideline/pc_create_or_update_spec.rb`

## Slice G: Messaging

Implemented on 2026-04-29.

### What changed

- JMS and AMS dispatchers now normalize V6 inbound resource names to the existing Rails handler names: `organisation` -> `provider`, `deployable_application` -> `deployable_service`, and `interoperability_record` -> `guideline`.
- Both dispatchers read either the V6 body key or the legacy internal key, so cutover messages can use `organisation`/`deployableApplication`/`interoperabilityRecord` while V5 fallback messages still work.
- JMS now routes `interoperability_record.*` messages to `Guideline::PcCreateOrUpdateJob` / `Guideline::DeleteJob`, matching AMS behavior.
- AMS subscriptions now use the V6 hard-cut topic list for in-scope entities: `mp-organisation-*` and `mp-deployable_application-*` replaced the old Provider/DeployableService topic names.
- README now documents the V6 `MP_STOMP_DESTINATION` wildcard set for the ops-managed STOMP subscriber setting.

### What to watch out for

- Adapter and TrainingResource remain out of scope. Tests assert that adapter messages are treated as unsupported rather than silently routed.
- `metadata.modifiedAt` still uses Unix milliseconds. The ISO date change applies to entity fields such as `publishingDate`, not the JMS/AMS envelope.
- `rg -n -e "(provider|deployable_software)\.(create|update|delete)" app/ config/` is noisy because it also matches Ruby method calls like `provider.update(...)`; inspect hits as topic strings before treating them as V5 messaging leftovers.
- This repository does not currently have a tracked `.env.example`, so only README was updated for the STOMP destination documentation.

### Validation run

- `ruby -c app/services/jms/manage_message.rb`
- `ruby -c app/services/ams/manage_message.rb`
- `ruby -c spec/services/jms/manage_message_spec.rb`
- `ruby -c spec/services/ams/manage_message_spec.rb`
- `bundle exec rspec spec/services/jms/manage_message_spec.rb spec/services/ams/manage_message_spec.rb`
- `bundle exec rspec spec/services/jms/ spec/services/ams/ spec/jobs/`
- `bundle exec rubocop app/services/jms/manage_message.rb app/services/ams/manage_message.rb spec/services/jms/manage_message_spec.rb spec/services/ams/manage_message_spec.rb`
- `grep -cE "mp-(provider|deployable_service)-" config/ams_subscriber.yml` (0)
- `grep -cE "mp-(organisation|deployable_application)-" config/ams_subscriber.yml` (6)
- `docker compose up -d active_mq`
- `bin/rails runner 'require "stomp"; ... Stomp::Client.open("stomp://artemis:artemis@localhost:61613"); ... publish("/topic/eosc.organisation.update", ...)'` (published successfully)

## Slice F: Catalogue

Checked on 2026-04-29.

### What changed

- No code changes were made. Catalogue remains an explicit V5-shaped exception in the V5 -> V6 migration.
- Existing Catalogue model/importer behavior still uses structured contacts, networks, tags, location fields, multimedia, scientific domains, and `users`-derived data administrators.
- The shared compatibility surface required by Catalogue is still present: `Contact`, `MainContact`, `PublicContact`, `Vocabulary::Network`, `PROVIDER_NETWORK`, `map_networks`, `map_contact`, and `map_data_administrator`.
- No `/public/catalogue` import path was added and no `catalogues.public_contact_emails` column was introduced.

### What to watch out for

- Do not treat Catalogue hits in removed Provider/Service field greps as cleanup targets. Catalogue owns those V5-shaped fields until Athena publishes a concrete V6 Catalogue contract.
- `rake import:catalogues` is outside the V6 integration matrix and still follows the existing Catalogue import path where supported.
- Future cleanup should keep documenting Catalogue as the reason structured contact/network compatibility remains after Provider and Service moved to email-array contacts.

### Validation run

- `bundle exec rspec spec/services/importers/catalogue_spec.rb spec/services/catalogue/pc_create_or_update_spec.rb spec/requests/api/v1/ess/catalogues_controller_spec.rb`

## Slice E: DeployableService

Implemented on 2026-04-29.

### What changed

- DeployableService import now targets the V6 `/public/deployableApplication` endpoint while keeping the Rails `DeployableService` class/table.
- Deployable Application storage now includes `publishing_date`, `resource_type`, `public_contact_emails`, `license_name`, `license_url`, and `urls`; the old `software_license` column was removed.
- Import mapping now consumes V6 `resourceOwner`, `nodePID`, `publicContacts`, `publishingDate`, `type`, `urls`, and optional `license`, while skipping `alternativePIDs` storage per D14.
- ESS serialization and the public show page were updated to expose V6-compatible deployable application fields.

### What to watch out for

- `Importers::DeployableService` returns `logo_url` for importer orchestration, but persistence paths must delete it before assigning attributes to `DeployableService`.
- ESS date serialization needs an explicit `publishing_date` method; otherwise request specs compare JSON strings to `Date` objects.
- Keep `url` as a compatibility column for ordering/deployment links and store the full V6 URL array in `urls`.
- Do not add DeployableService alternative PID joins in this slice; live integration records currently do not require them.

### Validation run

- `ruby -c app/models/deployable_service.rb`
- `ruby -c app/services/importers/deployable_service.rb`
- `ruby -c lib/import/deployable_services.rb`
- `ruby -c db/migrate/20260429160000_update_deployable_services_to_v6.rb`
- `bin/rails db:migrate`
- `bundle exec rspec spec/models/deployable_service_spec.rb spec/services/importers/deployable_service_spec.rb spec/serializers/ess/deployable_service_serializer_spec.rb spec/services/deployable_service/pc_create_or_update_spec.rb spec/requests/api/v1/ess/deployable_services_controller_spec.rb`
- `RUBOCOP_CACHE_ROOT=/tmp/rubocop_cache bundle exec haml-lint app/views/deployable_services/show.html.haml`
- `MP_IMPORT_EOSC_REGISTRY_URL=https://integration.providers.sandbox.eosc-beyond.eu/api MP_IMPORT_TOKEN= DRY_RUN=true bundle exec rake import:deployable_services` (8 processed)

## Slice D: Datasource

Implemented on 2026-04-29.

### What changed

- Datasource import now targets the V6 `/public/datasource` endpoint, consumes flat `DataSource` payloads, and creates Datasource STI records when no existing EOSC Registry source is present.
- Datasource-specific V5 storage was removed: submission/preservation policy URLs, `harvestable`, legacy `datasource_id`, persistent identity system tables/models, and research-product policy/licensing associations.
- `research_product_types` is now stored as a plain string array on `services`.
- Backoffice/public Datasource presentation now uses the shared V6 Service surface plus `version_control`, `thematic`, `jurisdiction`, `datasource_classification`, and `research_product_types`.
- ESS Datasource serialization was reduced to the V6 Datasource-specific fields.

### What to watch out for

- Rswag regenerates top-level swagger docs but does not rewrite the checked-in datasource component schema; review `swagger/v1/ess/datasource/datasource_read.json` manually after serializer changes.
- The live Datasource API still returns `accessTypes` as a bare string. Keep the shared Service importer wrapping this field with `Array(...)`.
- `researchProductTypes` remains a plain string array even when values look like vocabulary EIDs; do not reintroduce `DS_RESEARCH_ENTITY_TYPE` lookup.

### Validation run

- `bin/rails db:migrate`
- `bundle exec rspec spec/models/datasource_spec.rb spec/services/importers/datasource_spec.rb spec/policies/backoffice/datasource_policy_spec.rb spec/serializers/ess/datasource_serializer_spec.rb spec/policies/backoffice/service_policy_spec.rb spec/requests/api/v1/ess/datasources_controller_spec.rb`
- `MP_IMPORT_EOSC_REGISTRY_URL=https://integration.providers.sandbox.eosc-beyond.eu/api MP_IMPORT_TOKEN= DRY_RUN=true bundle exec rake import:datasources` (2 processed)

## Slice C: Service end-to-end

Implemented on 2026-04-29.

### What changed

- Service import now targets the V6 `/public/service` endpoint and consumes the flat Service payload while tolerating legacy wrapped fixtures in tests.
- Service storage was reduced to the V6-compatible field set, with `public_contact_emails`, `publishing_date`, `resource_type`, and `urls` added.
- Removed Service-only V5 joins and form/view paths for target users, related platforms, relationships, structured contacts, multimedia/use-case links, availability, maturity, attribution, and financial sections.
- Search data, public search facets, ESS serialization, and backoffice/public presentation paths now use the V6 Service surface.

### What to watch out for

- Existing non-feature specs still contain old Service expectations around removed filters, join models, ESS schemas, AOD platform behavior, and activation-message flows. These need test/schema cleanup or explicit pending markers in follow-up cleanup work.
- `contacts` is the actual STI table for `PublicContact`; Service contact migrations should not assume a physical `public_contacts` table.
- Some compatibility stubs remain for ordering flows (`aod?`, `activate_message`) so removed Service columns do not crash current order-status code before that workflow is simplified.

## Test stabilization after Slice B

Implemented on 2026-04-29.

### What changed

- The current non-feature baseline was restored: model, controller, request, policy, job, importer, JMS/AMS, and service specs can be run with `bundle exec rspec --tag ~type:feature`.
- Publishable/JMS specs now assert queued publish jobs instead of depending on a live STOMP connection.
- Request specs include Devise integration helpers, so `sign_in` works for request specs as well as controller specs.
- Offer factories now keep `Offer#order_type` aligned with the associated Service order type for open access, fully open access, and other offer variants.
- Import task specs isolate `ENV.fetch` values, preventing local `.env` tokens from changing spec expectations.
- Backoffice provider/service delete and deleted-resource status actions now use the current service object and policy behavior.
- `Presentable::ProviderInfoComponent` now skips unsupported provider fields instead of assuming every provider responds to service-era methods.

### What to watch out for

- Keep current-baseline specs separate from future-slice expectations. If a spec asserts V6 behavior that is not implemented in the current slice, either update it to the current behavior or mark it pending with a specific reason.
- Do not reintroduce live JMS/STOMP dependencies into model/service specs. Use `Jms::PublishJob` expectations for application behavior and keep transport coverage in the JMS/AMS transport specs.
- Avoid relying on local environment variables in task specs. Stub `ENV.fetch` or otherwise isolate the environment; local `.env` values can make the suite non-reproducible.
- Feature specs are not a reliable migration guide right now. Several feature examples still encode old UI labels, removed vocabulary routes, and future deployable-service ordering flows. Update those together with the slice that owns the UI/workflow change.
- Chrome/Chromedriver is technically unblocked, but a long full-suite feature run can still collapse into cascading `invalid session id` failures after Chrome disconnects. Treat failures after the browser session is lost as harness noise, not independent app failures.
- DeployableService bundle ordering remains future work. Current `Bundle` still belongs to `Service`, so deployable bundle specs should stay pending until the model/workflow slice supports them.

### Validation run

- `bundle exec rspec --tag ~type:feature` (2124 examples, 0 failures, 21 pending)
- `bundle exec rspec spec/features/backoffice/services_spec.rb:924`
- `bundle exec rspec spec/features/backoffice/services_spec.rb:170`

## Slice B: Provider end-to-end

Implemented on 2026-04-29.

### What changed

- Provider import now reads the V6 `/public/organisation` shape directly; the old V5 `public/provider/bundle` wrapper is no longer used.
- Provider contact storage moved from structured `MainContact`/`PublicContact` rows to `providers.public_contact_emails`.
- Provider V5 profile columns and associations were removed from the live model path: address fields, tags, scientific domains, structure/maturity/dependency vocabularies, certifications, affiliations, participating countries, and national roadmaps.
- Backoffice Provider forms and wizard steps now expose only V6-compatible Provider fields plus local Marketplace managers.
- ESS Provider serialization was reduced to V6-compatible fields and emits `public_contact_emails`.

### What to watch out for

- Data migrations that backfill from associations being removed in the same slice should not call the current Rails model association. Use migration-local table classes or SQL; otherwise a fresh `db:migrate` can fail after the model has been trimmed.
- Development seed tasks need the same removed-field cleanup as importers, factories, forms, and serializers. `rails dev:prime` still assigned Provider `tag_list` after tags were removed from the V6 Provider model, causing `ActiveModel::UnknownAttributeError`.
- `public_contact_emails` textareas need controller normalization before strong params. The regular backoffice update path and the wizard path have separate controllers, so both need the string-to-array split.
- Shared presentable components assumed Provider responded to service-era methods like `scientific_domains`, `public_contacts`, and `tag_list`. Provider-specific branches need explicit guards or a Provider-only field list.
- `MainContact`/`PublicContact` classes and Catalogue contact usage remain valid because Catalogue stays V5-shaped.
- The focused Provider policy spec currently has a pre-existing expectation mismatch: `Backoffice::ProviderPolicy#index?/show?/new?/create?` grant access to any present user, while the spec expects a regular user to be denied.

### Validation run

- `ruby -c app/models/provider.rb`
- `ruby -c app/services/importers/provider.rb`
- `ruby -c lib/import/providers.rb`
- `ruby -c app/controllers/backoffice/providers_controller.rb`
- `ruby -c app/controllers/backoffice/providers/steps_controller.rb`
- `ruby -c app/policies/backoffice/provider_policy.rb`
- `ruby -c db/migrate/20260429130000_add_public_contact_emails_to_providers.rb`
- `ruby -c db/migrate/20260429131000_strip_provider_to_v6.rb`
- `bin/rails db:migrate`
- `bundle exec rspec spec/services/importers/provider_spec.rb`
- `bundle exec rspec spec/services/provider/pc_create_or_update_spec.rb`
- `bundle exec rspec spec/models/provider_spec.rb:20`
- `RUBOCOP_CACHE_ROOT=/tmp/rubocop_cache bundle exec haml-lint app/views/backoffice/providers app/views/providers/show.html.haml app/views/components/presentable/header_component/_badges.html.haml app/views/components/presentable/sidebar_component/_array.html.haml`
- `MP_IMPORT_EOSC_REGISTRY_URL=https://integration.providers.sandbox.eosc-beyond.eu/api MP_IMPORT_TOKEN= DRY_RUN=true bundle exec rake import:providers` (20 processed)

Known validation limitations:

- `bundle exec rspec spec/models/provider_spec.rb spec/services/importers/provider_spec.rb` still hits the existing publishable JMS examples and failed locally with `Stomp::Error::NilMessageError` / `stream closed in another thread`.
- `bundle exec rspec spec/policies/backoffice/provider_policy_spec.rb` fails on the pre-existing regular-user access expectation noted above.

## Slice A: Vocabularies + Importable cleanup

Implemented on 2026-04-29.

### What changed

- `Importable` was trimmed to the V6/shared helper surface: 18 `map_` helpers remain, plus `object_status`, `fetch_ppid`, `extract_public_contact_emails`, and `fetch_ppid_from_alt_pids`.
- `map_link` now only builds `Link::MultimediaUrl`; the old use-case and research-product license link STI classes remain for compatibility but are no longer created by the shared importer path.
- Provider, Service, and Datasource importers no longer call mapper helpers for removed V5 vocabulary concepts.
- `Importers::Request` no longer sends an `Authorization: Bearer ` header when the token is blank.
- `VOCABULARY_TYPES` now exposes only the V6-supported/kept vocabulary management entries.
- `Import::Vocabularies::ACCEPTED_VOCABULARIES` now imports only:
  `CATEGORY`, `SUBCATEGORY`, `SCIENTIFIC_DOMAIN`, `SCIENTIFIC_SUBDOMAIN`, `TRL`, `ACCESS_TYPE`, `NODE`, `DS_JURISDICTION`, `DS_CLASSIFICATION`, `PROVIDER_LEGAL_STATUS`, `PROVIDER_HOSTING_LEGAL_ENTITY`, and `PROVIDER_NETWORK`.
- Added a non-destructive `RemoveV5Vocabularies` migration. It records the migration boundary but intentionally does not drop tables, models, or rows.
- Updated the vocabulary import spec expectations for the reduced V6 import scope.

### What to watch out for

- Slice A is intentionally non-destructive. Compatibility models/tables such as `TargetUser`, `Platform`, `ServiceRelationship`, `Vocabulary::FundingBody`, `Vocabulary::ServiceCategory`, and old link STI subclasses still need to exist until later slices remove all live call sites.
- `rdt:add_vocabularies` still seeds compatibility vocabularies from local data. That is expected and separate from the Provider Catalogue V6 import scope.
- For live dry-run imports, pass an empty token explicitly:

  ```bash
  env MP_IMPORT_TOKEN= DRY_RUN=true bundle exec rake import:vocabularies
  ```

  With the local `.env` token present, the Provider Catalogue API can fail; the empty token path was validated after making bearer auth optional.

- The live V6 dry run reported `TARGET_USER`, `DS_RESEARCH_ENTITY_TYPE`, and `DS_PERSISTENT_IDENTITY_SCHEME` as not implemented, which is expected for Slice A.
- Do not remove `PROVIDER_NETWORK` yet. Catalogue remains V5-shaped and still needs network compatibility.

### Validation run

- `ruby -c app/models/concerns/importable.rb`
- `ruby -c app/services/importers/provider.rb`
- `ruby -c app/services/importers/service.rb`
- `ruby -c app/services/importers/datasource.rb`
- `ruby -c app/services/importers/request.rb`
- `ruby -c db/migrate/20260429120000_remove_v5_vocabularies.rb`
- `bin/rails db:migrate`
- `bin/rails db:prepare`
- `bin/rails runner 'puts [Vocabulary::FundingBody.name, Vocabulary::ServiceCategory.name, Platform.table_name, TargetUser.table_name, Link::UseCasesUrl.name].join($/)'`
- `bin/rails rdt:add_vocabularies`
- `bundle exec rspec spec/lib/import/vocabularies_spec.rb`
- `env MP_IMPORT_TOKEN= DRY_RUN=true bundle exec rake import:vocabularies`
