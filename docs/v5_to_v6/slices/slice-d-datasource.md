# Slice D: Datasource (0.5d)

Datasource is an STI subclass of `Service` (`type = "Datasource"` in DB). V6 makes it a regular Service flavour with a few extra fields. Most Datasource-specific scaffolding is **removed**, not reshaped — the V6 API no longer sends `persistentIdentitySystems`, `researchEntityTypes`, `researchProductLicensings`, `researchProductMetadataLicensing`, `researchProductAccessPolicies`, or `researchProductMetadataAccessPolicies`.

**Depends on Slice 0 decisions:** D3 (drop removed DS data), D4 (existing DS rows keep V5 `pid`; no rename), D9 (drop `DS_RESEARCH_ENTITY_TYPE` / `DS_PERSISTENT_IDENTITY_SCHEME` vocabularies), D11 (`"type": "DataSource"` → STI `Datasource`), D13 (`accessTypes` is a **bare string** on Datasource — integration returns `"access_type-remote"`, NOT an array; `Array()` wrap is the right idiom since Service returns an array), D14 (reuse `alternative_identifiers` for `alternativePIDs`), D18 (URL bug).

**Depends on Slice A:** `Vocabulary::EntityType` / `Vocabulary::EntityTypeScheme` / `Vocabulary::ResearchProductAccessPolicy` / `Vocabulary::ResearchProductMetadataAccessPolicy` classes and models are deleted there.

**Depends on Slice C:** Slice C already deletes `service_vocabularies` rows for `Vocabulary::EntityType`, `ResearchProductAccessPolicy`, `ResearchProductMetadataAccessPolicy` and `Link::ResearchProductLicenseUrl` / `Link::ResearchProductMetadataLicenseUrl`. Slice D does NOT repeat those deletions.

---

## V6 API response

Live shape from `GET /public/datasource/all`:

```json
{
  "id": "21.T15999/2shDkg",
  "name": "CESSDA Data Catalogue",
  "alternativePIDs": [{"pid": "...", "pidSchema": "openaire"}],
  "webpage": "...",
  "description": "...",
  "logo": "...",
  "scientificDomains": [...],
  "categories": [...],
  "accessTypes": "access_type-virtual",
  "tags": ["..."],
  "trl": "trl-8",
  "termsOfUse": "...",
  "privacyPolicy": "...",
  "accessPolicy": "...",
  "orderType": "order_type-open_access",
  "order": "...",
  "nodePID": "node-cessda",
  "type": "DataSource",
  "publishingDate": "2026-03-15",
  "publicContacts": ["default@example.com"],
  "resourceOwner": "21.T15999/dAyH3s",
  "serviceProviders": ["21.T15999/dAyH3s"],
  "jurisdiction": "ds_jurisdiction-global",
  "versionControl": false,
  "researchProductTypes": ["ds_research_entity_type-research_data"],
  "datasourceClassification": "ds_classification-aggregators",
  "thematic": true
  // NOT PRESENT: persistentIdentitySystems, researchEntityTypes,
  //   researchProductLicensings, researchProductMetadataLicensing,
  //   researchProductAccessPolicies, researchProductMetadataAccessPolicies,
  //   submissionPolicyUrl, preservationPolicyUrl, metadataLicense
  // DEAD but still emitted as null: harvestable. Importer ignores it; column is dropped.
}
```

**Response is flat** — no `{datasource: {...}, resourceExtras: {...}}` wrapper.

**`researchProductTypes`** is a string array of EIDs, stored verbatim (no vocabulary lookup per D9).

---

## D1. DB migration — strip DS-specific columns, drop PID system tables (20 min)

**File:** `db/migrate/YYYYMMDDHHMMSS_strip_datasource_to_v6.rb`

### Columns to REMOVE from `services` table

```
submission_policy_url
preservation_policy_url
harvestable
datasource_id  (string — legacy external id, superseded by `pid`)
```

### Columns to ADD to `services` table

```
research_product_types :string, array: true, default: []
```

Only ONE new column. No `metadata_license_name` / `metadata_license_url` — V6 API does not send them.

### Columns to KEEP

`jurisdiction_id` (already exists, now used by all Services per Slice C), `datasource_classification_id`, `version_control`, `thematic`.

### Tables to DROP entirely

```
persistent_identity_systems
persistent_identity_system_vocabularies
```

Rationale: V6 does not send `persistentIdentitySystems` at all. The current structure (`entity_type_id`, `entity_type_scheme_ids`) references `Vocabulary::EntityType` / `EntityTypeScheme` — both deleted in Slice A. Nothing left to populate these tables.

### Full migration

```ruby
class StripDatasourceToV6 < ActiveRecord::Migration[7.2]
  def up
    add_column :services, :research_product_types, :string, array: true, default: []

    drop_table :persistent_identity_system_vocabularies, if_exists: true
    drop_table :persistent_identity_systems, if_exists: true

    remove_column :services, :submission_policy_url, :string, if_exists: true
    remove_column :services, :preservation_policy_url, :string, if_exists: true
    remove_column :services, :harvestable, :boolean, default: false, if_exists: true
    remove_column :services, :datasource_id, :string, if_exists: true
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
```

### Validate

```bash
rails db:migrate
grep -A 100 'create_table "services"' db/schema.rb | grep -cE "(submission_policy_url|preservation_policy_url|harvestable|datasource_id)"
# Should return 0
grep -c "research_product_types" db/schema.rb
# Should return 1
grep -c "persistent_identity_systems" db/schema.rb
# Should return 0
```

---

## D2. Delete `PersistentIdentitySystem` model + join model (5 min)

**Files to delete:**

- `app/models/persistent_identity_system.rb`
- `app/models/persistent_identity_system_vocabulary.rb`

These classes are referenced nowhere except:

- `app/models/service.rb` lines 165-169 + 185-190 (removed in D3)
- `app/helpers/forms_helper.rb` (datasource form helper — removed in D6)
- `app/policies/backoffice/service_policy.rb` (`persistent_identity_systems_attributes` — removed in D5)
- `app/policies/backoffice/datasource_policy.rb` (check + remove)
- `app/helpers/presentable/details_helper.rb` (show-page helper — remove rendering block)
- `swagger/v1/ess/datasource/datasource_read.json` (API docs — regenerate via `./bin/rails rswag` after D7)
- `spec/policies/backoffice/service_policy_spec.rb` (remove referenced permitted attrs)

---

## D3. Update Service + Datasource models (30 min)

### `app/models/service.rb`

Remove these lines (they were left in place by Slice C; D3 removes them now):

```ruby
# DELETE these associations and nested-attributes block:
has_many :link_research_product_license_urls, ...
has_many :link_research_product_metadata_license_urls, ...
has_many :persistent_identity_systems, ...
belongs_to :datasource_classification, ...         # DELETE only if you're removing DS classification support — see below
has_many :research_entity_types, ...
has_many :research_product_access_policies, ...
has_many :research_product_metadata_access_policies, ...

accepts_nested_attributes_for :persistent_identity_systems, ...
accepts_nested_attributes_for :link_research_product_license_urls, ...
accepts_nested_attributes_for :link_research_product_metadata_license_urls, ...
```

### Keep on `Service` (used by Datasource STI)

- `belongs_to :jurisdiction, class_name: "Vocabulary::Jurisdiction", optional: true` (already used by Service post-Slice C)
- `belongs_to :datasource_classification, class_name: "Vocabulary::DatasourceClassification", optional: true`
- The `services.version_control`, `services.thematic`, `services.research_product_types`, `services.datasource_classification_id` columns

### Add on `Service`

```ruby
# research_product_types is a plain string array; default Rails accessor suffices.
auto_strip_attributes :research_product_types, nullify_array: false
```

### `app/models/datasource.rb` — full rewrite

```ruby
# frozen_string_literal: true

class Datasource < Service
  include Rails.application.routes.url_helpers

  def self.model_name
    Service.model_name
  end

  def self.type
    "Datasource"
  end

  friendly_id :name, use: :slugged

  before_save { self.pid = sources&.first&.eid if pid.blank? }

  private

  def _provider_search_link(target_name, filter_query, default_path = nil)
    search_base_url = Mp::Application.config.search_service_base_url
    enable_external_search = Mp::Application.config.enable_external_search
    if enable_external_search
      search_base_url + "/search/data_source?q=*&fq=#{filter_query}:(%22#{target_name}%22)"
    else
      default_path || provider_path(self)
    end
  end
end
```

### Removed from `Datasource`

- `before_save` block that rejected empty `persistent_identity_systems`
- `accepts_nested_attributes_for :persistent_identity_systems`
- `self.pid = ... || abbreviation` fallback (`abbreviation` column deleted in Slice C)

### Validate

```bash
grep -nE "(persistent_identity_systems|research_entity_types|research_product_access_policies|research_product_metadata_access_policies|link_research_product_license|link_research_product_metadata_license)" app/models/service.rb app/models/datasource.rb
# Should return empty
bundle exec rails runner 'pp Datasource.new.valid? ; pp Datasource.new.errors.full_messages'
# No errors referencing removed associations
```

---

## D4. Rewrite `Importers::Datasource` (15 min)

**File:** `app/services/importers/datasource.rb`

V6 Datasource extends Service — `Importers::Service` already maps all shared fields (via Slice C5). `Importers::Datasource` only produces the DS-specific delta and is composed with the Service result by the orchestrator.

```ruby
# frozen_string_literal: true

class Importers::Datasource < ApplicationService
  include Importable

  def initialize(data)
    super()
    @data = data
  end

  def call
    {
      version_control: @data["versionControl"].nil? ? false : !!@data["versionControl"],
      datasource_classification: map_datasource_classification(@data["datasourceClassification"]),
      research_product_types: Array(@data["researchProductTypes"]),
      thematic: !!@data["thematic"]
    }
  end
end
```

### Removed mappings

`submissionPolicyURL`, `preservationPolicyURL`, `harvestable`, `persistentIdentitySystems`, `researchEntityTypes`, `researchProductLicensings`, `researchProductMetadataLicensing`, `researchProductAccessPolicies`, `researchProductMetadataAccessPolicies`, `jurisdiction` (handled by `Importers::Service` now).

### Validate

```bash
grep -cE "(submissionPolicyURL|preservationPolicyURL|harvestable|persistentIdentitySystems|researchEntityTypes|researchProductLicensings|researchProductMetadataLicensing|researchProductAccessPolicies|researchProductMetadataAccessPolicies|map_entity_types|map_persistent_identity_system|map_access_policies|map_metadata_access_policies)" app/services/importers/datasource.rb
# Should return 0
```

---

## D5. Rewrite `Import::Datasources` orchestrator (30 min)

**File:** `lib/import/datasources.rb`

### URL bug (D18)

Current code passes `"/public/datasource/adminPage"`. `Importers::Request#all` appends `/all?quantity=10000&from=0`. Change to:

```ruby
Importers::Request.new(@eosc_registry_base_url, "public/datasource", faraday: @faraday, token: @token).call
```

(No leading slash — matches Slices B and C.)

### Response shape change

V6 response is flat (no `datasource` wrapper, no `identifiers.alternativeIdentifiers`, no `serviceId`). Rewrite the iteration:

```ruby
response.body["results"]
  .select { |res| @ids.empty? || @ids.include?(res["id"]) }
  .each do |ds_data|
    output.append(ds_data)

    # D11: API returns "DataSource" (capital S). Rails STI discriminator is "Datasource".
    raise "Unexpected type #{ds_data["type"]}" unless ds_data["type"] == "DataSource"

    synchronized_at = Time.now.to_i # V6 public endpoint omits metadata.modifiedAt

    service_attrs = Importers::Service.call(ds_data, synchronized_at, @eosc_registry_base_url, @token)
    ds_delta = Importers::Datasource.call(ds_data)
    attrs = service_attrs.merge(ds_delta).merge(type: "Datasource")
    image_url = attrs.delete(:logo_url)

    source = ServiceSource.find_by(eid: ds_data["id"], source_type: "eosc_registry")

    if source.nil?
      created += 1
      log "Adding [NEW] datasource: #{attrs[:name]}, eid: #{ds_data["id"]}"
      next if @dry_run

      ds = Datasource.new(attrs)
      if ds.valid?
        Importers::Logo.call(ds, image_url) unless @rescue_mode
        ds = Service::Create.call(ds) # Service::Create works for STI Datasource
        source = ServiceSource.create!(service_id: ds.id, eid: ds.pid, source_type: "eosc_registry")
        ds.update_column(:upstream_id, source.id) if @default_upstream == :eosc_registry
      else
        ds.status = :draft
        ds.save(validate: false)
        source = ServiceSource.create!(service_id: ds.id, eid: ds.pid, source_type: "eosc_registry")
        log "Datasource #{ds.name}, eid: #{ds.pid} saved with errors: #{ds.errors.full_messages}"
      end
    else
      existing = Datasource.find_by(id: source.service_id)
      if existing&.upstream_id == source.id
        updated += 1
        log "Updating [EXISTING] datasource #{attrs[:name]}, id: #{source.id}, eid: #{ds_data["id"]}"
        next if @dry_run
        Importers::Logo.call(existing, image_url) unless @rescue_mode
        Service::Update.call(existing, attrs)
      else
        not_modified += 1
        log "Datasource upstream is not set to EOSC Registry, not updating #{existing&.name}, id: #{source.id}"
      end
    end
  rescue ActiveRecord::RecordInvalid => e
    log "[ERROR] - #{e}! #{ds_data["name"]} (eid: #{ds_data["id"]}) will NOT be created"
  rescue StandardError => e
    log "[ERROR] - Unexpected #{e}! #{ds_data["name"]} (eid: #{ds_data["id"]}) will NOT be created"
  end
```

### Removed from orchestrator

- `datasource_data["datasource"]` unwrap
- `datasource_data.dig("identifiers", "alternativeIdentifiers")` ppid extraction (now handled in `Importers::Service` via `alternativePIDs`)
- `eid(datasource_data)` helper using `serviceId` (V6 uses top-level `id`)
- `datasource_data["serviceId"]`

### Behaviour change

V5 orchestrator only updated existing DS; never created new ones ("Service id ... doesn't exist" warning). V6 creates Datasources from scratch because the V6 API is the authoritative source for the Datasource entity. This is intentional per D4 (new DS records imported under V6 carry whatever `id` the PC returns).

### Validate

```bash
DRY_RUN=true bundle exec rake import:datasources 2>&1 | tail -30
# Should show "Adding [NEW] datasource" or "Updating [EXISTING]", no NoMethodError
```

---

## D6. Update backoffice datasource forms (45 min)

### Delete partials entirely

- `app/views/backoffice/services/form/_datasource_policies.html.haml` — submission/preservation/harvestable
- `app/views/backoffice/services/form/_persistent_identity_systems.html.haml` (if it exists)
- `app/views/backoffice/services/form/_research_product_*.html.haml` (license, access policy fields)

### Rewrite/keep

- `app/views/backoffice/services/form/_datasource_content.html.haml`:
  - Keep: `version_control` checkbox, `thematic` checkbox, `datasource_classification_id` select (from `Vocabulary::DatasourceClassification`), `jurisdiction_id` select (from `Vocabulary::Jurisdiction`)
  - Remove: `research_entity_type_ids` multi-select, `harvestable` checkbox, `submission_policy_url`, `preservation_policy_url`
  - Add: `research_product_types[]` multi-value text input (string array, no vocabulary lookup)

Example HAML for `research_product_types`:

```haml
.form-group
  = f.label :research_product_types, "Research product types"
  = f.text_area :research_product_types_as_text, value: (form.object.research_product_types || []).join("\n"), rows: 3, placeholder: "one EID per line, e.g. ds_research_entity_type-research_data"
```

Controller glue (same pattern as `public_contact_emails` in Slice C10):

```ruby
if params.dig(:service, :research_product_types_as_text)
  types = params[:service][:research_product_types_as_text].to_s.split(/\r?\n/).map(&:strip).reject(&:empty?)
  params[:service][:research_product_types] = types
end
```

### `app/helpers/forms_helper.rb` / `app/helpers/presentable/details_helper.rb`

Grep for `persistent_identity_system` and delete the helper blocks that render the removed fields. Same for `research_entity_type`, `research_product_access_policies`, etc.

### Validate

```bash
grep -rlE "(persistent_identity_system|research_entity_type|research_product_access|research_product_metadata|research_product_license|submission_policy|preservation_policy|harvestable)" app/views/backoffice/services/ app/helpers/
# Should return empty
```

---

## D7. Update policies + serializers (20 min)

### `app/policies/backoffice/service_policy.rb`

Already cleaned in Slice C11. Double-check the following are absent:

- `[persistent_identity_systems_attributes: ...]`
- `[research_entity_type_ids: []]`
- `[research_product_access_policy_ids: []]`
- `[research_product_metadata_access_policy_ids: []]`
- `[entity_type_scheme_ids: []]`
- `[link_research_product_license_urls_attributes: ...]`
- `[link_research_product_metadata_license_urls_attributes: ...]`
- `:submission_policy_url`, `:preservation_policy_url`, `:harvestable`

Add: `[research_product_types: []]`.

### `app/policies/backoffice/datasource_policy.rb`

Inherits from / delegates to `ServicePolicy`. Remove any DS-specific overrides of those attributes.

### `app/serializers/ess/datasource_serializer.rb`

Inherits from `Ess::ServiceSerializer` (rewritten in Slice C8). Remove DS-only attributes for: `persistent_identity_systems`, `research_entity_types`, `research_product_access_policies`, `research_product_metadata_access_policies`, `link_research_product_license_urls`, `link_research_product_metadata_license_urls`, `submission_policy_url`, `preservation_policy_url`, `harvestable`.

Add:

```ruby
attributes :version_control, :thematic, :datasource_classification, :jurisdiction, :research_product_types
```

### Regenerate API docs

```bash
./bin/rails rswag
```

This updates `swagger/v1/ess/datasource/datasource_read.json`. Review the diff to confirm removed fields are gone.

---

## D8. Specs (20 min)

- `spec/services/importers/datasource_spec.rb` — new V6 JSON fixture (use the curl output from top of this file); expect only `version_control`, `datasource_classification`, `research_product_types`, `thematic`.
- `spec/models/datasource_spec.rb` — remove tests for `persistent_identity_systems`, `research_entity_types`, harvestable, submission/preservation policy URLs.
- `spec/policies/backoffice/service_policy_spec.rb` / `datasource_policy_spec.rb` — remove assertions on removed attributes, add `research_product_types`.
- `spec/serializers/ess/datasource_serializer_spec.rb` — update expected keys.

### Validate

```bash
bundle exec rspec spec/models/datasource_spec.rb \
                  spec/services/importers/datasource_spec.rb \
                  spec/policies/backoffice/datasource_policy_spec.rb \
                  spec/serializers/ess/datasource_serializer_spec.rb
```

---

## Validate (full slice)

```bash
# All DS-only references to removed concepts are gone:
rg -n "(persistent_identity_system|research_entity_type|research_product_access_polic|research_product_metadata_access_polic|link_research_product_license|link_research_product_metadata_license|submission_policy_url|preservation_policy_url|harvestable)" app/ lib/ spec/
# Should return empty (or only tests explicitly asserting "doesn't respond_to")

DRY_RUN=true bundle exec rake import:datasources 2>&1 | tail -20
# Should show "Adding [NEW] datasource: CESSDA Data Catalogue" etc., no 404, no NoMethodError

./bin/server
# Browse /services?type=datasource, /backoffice/services/:id/edit on a Datasource
# No 500s
```

**Commit.** Datasource is now V6.

---

## Out of scope for Slice D (documented decisions)

- Existing DS rows are NOT renamed (D4 default). They keep their V5 `pid`. A future per-owner consultation will decide the migration policy.
- `metadataLicense` storage — V6 API does not send it. Add columns in a follow-up if the field ever ships.
- DS now has its own PID prefix in V6. Marketplace does not need to mint PIDs (read-only import), so no prefix logic here.
- Global DS data migration (cross-node, etc.) handled in Slice J.
