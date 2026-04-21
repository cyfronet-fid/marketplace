# Slice H: Guideline / InteroperabilityGuideline (1d)

Extend the skeleton `Guideline` model to match V6 `InteroperabilityGuideline`. Also consolidate the fragmented import path: current state has `Guideline::PcCreateOrUpdate` (title/eid only), `lib/import/guidelines.rb` (title/eid only), no `Importers::Guideline`, and no `GuidelineSource`.

**Depends on Slice 0 decisions:** D14 (reuse `alternative_identifiers` for `alternativePIDs`), D15 (add `urls`), D16 (`nodePID` is EID), D17 (defensive `publicContacts`), D18 (URL construction).

**Depends on Slice G:** JMS routing for `interoperability_record.*` is added there. Slice H only needs the routing to exist — the alias table in `Jms::ManageMessage` maps it to `guideline`.

---

## V6 API response

`curl -s "https://integration.providers.sandbox.eosc-beyond.eu/api/public/interoperabilityRecord/all?quantity=10&from=0"` returns a shape of:

```json
{
  "id": "21.11171/EnMoNU",
  "name": "EOSC IF Guidelines for Data Sources to onboard Research Products",
  "description": "<p>These guidelines aim to provide orientation...</p>",
  "type": "InteroperabilityGuidelines",
  "publishingDate": "2026-03-15",
  "nodePID": "node-sandbox",
  "resourceOwner": "21.T15999/vSRLQL",
  "publicContacts": ["default@example.com"],
  "creators": [{ "email": "...", "firstName": "...", "lastName": "..." }],
  "resourceTypeInfo": { "resourceType": "API", "resourceTypeGeneral": "Guideline" },
  "relatedStandards": [{ "relatedStandardIdentifier": "OAI-PMH", "relatedStandardURI": "http://..." }]
  // Schema allows but no live record populates: license, alternativePIDs, urls
}
```

Cross-env note: `docs/v5_to_v6/swagger/prod.json` defines an `InteroperabilityRecord` schema with `resourceTypesInfo` (**plural**, array of `ResourceTypeInfo`). Integration/dev return the singular object `resourceTypeInfo`. The importer targets integration/dev (V6 preview). If a future prod rollout flips to plural-array, add a single `Array(@data["resourceTypeInfo"] || @data["resourceTypesInfo"]).first` shim at the top of `Importers::Guideline`.

`curl -s "https://integration.providers.sandbox.eosc-beyond.eu/api/public/resourceInteroperabilityRecord/all?catalogue_id=all"` returns `{total:0, results:[]}`. Endpoint exists; no link data yet.

**Key field changes vs. current Rails:**

- API sends `name`, current DB column is `title` → rename column to `name`
- API sends rich metadata, current model is 2 columns (`title`, `eid`) → widen

---

## H1. DB migration — extend guidelines table + create source table (30 min)

**File:** `db/migrate/YYYYMMDDHHMMSS_extend_guidelines_to_v6.rb`

```ruby
class ExtendGuidelinesToV6 < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def up
    rename_column :guidelines, :title, :name

    add_column :guidelines, :description, :text
    add_column :guidelines, :publishing_date, :date
    add_column :guidelines, :resource_type, :string # from type — "InteroperabilityGuidelines"
    add_column :guidelines, :resource_type_general, :string # from resourceTypeInfo.resourceTypeGeneral
    add_column :guidelines, :resource_type_detail, :string # from resourceTypeInfo.resourceType ("API", "Standard", etc.)
    add_column :guidelines, :license_name, :string
    add_column :guidelines, :license_url, :string
    add_column :guidelines, :creators, :jsonb, default: []
    add_column :guidelines, :node_pid, :string
    add_column :guidelines, :resource_owner_pid, :string # storing PID string directly, not FK (V5 pattern for interop records)
    add_column :guidelines, :public_contact_emails, :string, array: true, default: []
    add_column :guidelines, :related_standards, :jsonb, default: []
    add_column :guidelines, :urls, :string, array: true, default: []
    add_column :guidelines, :status, :string, default: "published"
    add_column :guidelines, :upstream_id, :integer
    add_column :guidelines, :synchronized_at, :datetime
    add_column :guidelines, :ppid, :string

    create_table :guideline_sources do |t|
      t.references :guideline, null: false, foreign_key: true
      t.string :source_type, null: false # "eosc_registry" plus any future sources
      t.string :eid, null: false # PC-issued id
      t.jsonb :errored # parity with ServiceSource / DeployableServiceSource
      t.timestamps
    end
    add_index :guideline_sources, %i[source_type eid], unique: true

    # Polymorphic alternative_identifiers — reuse existing table (D14). Add a join:
    create_table :guideline_alternative_identifiers, id: false do |t|
      t.bigint :guideline_id, null: false
      t.bigint :alternative_identifier_id, null: false
    end
    add_index :guideline_alternative_identifiers, :guideline_id
    add_index :guideline_alternative_identifiers, :alternative_identifier_id
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
```

### `name` vs `title` — explicit decision (resolves H3 ambiguity)

V6 API sends `"name"`. The existing `title` column is renamed to `name`. All references in views/helpers/tests must be updated (see H6). There is no backwards-compat alias.

### `resourceTypeInfo` flattening

V6 nests `{resourceType, resourceTypeGeneral}` under `resourceTypeInfo`. Stored flat as `resource_type_general` (`"Guideline"`) and `resource_type_detail` (`"API"`). Separate from `resource_type` (`"InteroperabilityGuidelines"` — the top-level `type` field).

### `resource_owner` as string, not FK

Stored as raw PID string (`"21.T15999/vSRLQL"`). Not resolved to `Provider` at import time — the referenced Provider may not exist in MP yet (import ordering). Views can do a lookup when rendering.

### Validate

```bash
rails db:migrate
grep -A 25 'create_table "guidelines"' db/schema.rb | grep -cE "\b(name|description|publishing_date|resource_type|resource_type_general|resource_type_detail|license_name|license_url|creators|node_pid|resource_owner_pid|public_contact_emails|related_standards|urls|status|upstream_id|synchronized_at|ppid)\b"
# Should return 19+
grep -c "create_table \"guideline_sources\"" db/schema.rb
# Should return 1
```

---

## H2. Create `GuidelineSource` model (5 min)

**File:** `app/models/guideline_source.rb` (new)

```ruby
# frozen_string_literal: true

class GuidelineSource < ApplicationRecord
  belongs_to :guideline

  validates :source_type, presence: true
  validates :eid, presence: true, uniqueness: { scope: :source_type }

  scope :from_eosc_registry, -> { where(source_type: "eosc_registry") }
end
```

Columns: `guideline_id, source_type, eid, errored, created_at, updated_at` (see H1). Parity with `ServiceSource` and `DeployableServiceSource` — no more, no less.

---

## H3. Extend `Guideline` model (15 min)

**File:** `app/models/guideline.rb`

```ruby
# frozen_string_literal: true

class Guideline < ApplicationRecord
  has_many :service_guidelines, dependent: :destroy
  has_many :services, through: :service_guidelines

  has_many :sources, class_name: "GuidelineSource", dependent: :destroy
  belongs_to :upstream, class_name: "GuidelineSource", foreign_key: "upstream_id", optional: true

  has_many :guideline_alternative_identifiers
  has_many :alternative_identifiers, through: :guideline_alternative_identifiers

  accepts_nested_attributes_for :alternative_identifiers, reject_if: :all_blank, allow_destroy: true

  validates :name, presence: true
  validates :eid, presence: true, uniqueness: true

  # Friendly finders for views
  def resource_owner
    Provider.find_by(pid: resource_owner_pid)
  end

  def node
    Vocabulary::Node.find_by(eid: node_pid)
  end
end
```

### Removed / not added

- No `publishable` / `statusable` concerns — Guideline is import-only read-only content for now. If backoffice needs status management later, add in a follow-up.
- No friendly_id slug — views reference guidelines by `eid`.

### Validate

```bash
bundle exec rails runner 'g = Guideline.new(eid: "test", name: "Test"); puts g.valid?'
# Should print true
```

---

## H4. Create `Importers::Guideline` (30 min)

**File:** `app/services/importers/guideline.rb` (new)

```ruby
# frozen_string_literal: true

class Importers::Guideline < ApplicationService
  include Importable

  def initialize(data, synchronized_at)
    super()
    @data = data
    @synchronized_at = synchronized_at
  end

  def call
    alt_pids = Array(@data["alternativePIDs"])
    rti = @data["resourceTypeInfo"].is_a?(Hash) ? @data["resourceTypeInfo"] : {}
    license = @data["license"].is_a?(Hash) ? @data["license"] : {}

    {
      eid: @data["id"],
      name: @data["name"],
      description: @data["description"],
      publishing_date: @data["publishingDate"],
      resource_type: @data["type"],
      resource_type_general: rti["resourceTypeGeneral"],
      resource_type_detail: rti["resourceType"],
      license_name: license["name"],
      license_url: license["url"],
      creators: Array(@data["creators"]),
      node_pid: @data["nodePID"], # singular string per V6
      resource_owner_pid: @data["resourceOwner"],
      public_contact_emails: extract_public_contact_emails(@data["publicContacts"]),
      related_standards: Array(@data["relatedStandards"]),
      urls: Array(@data["urls"]),
      alternative_identifiers: alt_pids.map { |p| map_alt_pid(p) }.compact,
      ppid: fetch_ppid_from_alt_pids(alt_pids),
      synchronized_at: @synchronized_at,
      status: :published
    }
  end
end
```

Helpers used (`extract_public_contact_emails`, `map_alt_pid`, `fetch_ppid_from_alt_pids`) already live in `Importable` (added in Slice B5).

`node_pid` is stored as-is (D16); no `map_nodes` call — the column is a plain string, not a join.

### Validate

```bash
grep -cE "(extract_public_contact_emails|map_alt_pid|fetch_ppid_from_alt_pids)" app/services/importers/guideline.rb
# Should return 3
```

---

## H5. Rewrite `Guideline::PcCreateOrUpdate` (20 min)

**File:** `app/services/guideline/pc_create_or_update.rb`

```ruby
# frozen_string_literal: true

class Guideline::PcCreateOrUpdate < ApplicationService
  def initialize(guideline_data, status, modified_at)
    super()
    @guideline_data = guideline_data
    @modified_at = modified_at
    @is_active = status == :published
    @guideline = Guideline.find_by(eid: guideline_data["id"])
  end

  def call
    attrs = Importers::Guideline.call(@guideline_data, @modified_at.to_i)
    if @guideline.nil?
      Guideline.create!(attrs) if @is_active
    else
      @guideline.update!(attrs)
      @guideline
    end
  end
end
```

Delegates all field parsing to `Importers::Guideline`. `@is_active` gate keeps parity with current behaviour (don't create suspended guidelines, but update existing ones regardless).

---

## H6. Rewrite `Import::Guidelines` orchestrator (45 min)

**File:** `lib/import/guidelines.rb`

### URL bug (D18)

Current code calls `Importers::Request.new(..., "public/interoperabilityRecord", ...)`. `Request#all` produces `public/interoperabilityRecord/all?quantity=10000&from=0`. **No change needed** — the URL construction is already correct for this endpoint.

`public/resourceInteroperabilityRecord` is special-cased inside `Importers::Request` (line 24: `"all?catalogue_id=all"`).

### Rewrite `import_guidelines`

```ruby
def import_guidelines
  log "Importing guidelines from EOSC Registry #{@eosc_registry_base_url}..."
  @request_guidelines = external_guidelines_data("public/interoperabilityRecord")

  @request_guidelines.each do |external_data|
    eid = external_data["id"]
    parsed = Importers::Guideline.call(external_data, Time.now.to_i)

    next if @dry_run

    source = GuidelineSource.find_by(source_type: "eosc_registry", eid: eid)
    existing = source && Guideline.find_by(id: source.guideline_id) || Guideline.find_by(eid: eid)

    existing.nil? ? create_guideline(parsed, eid) : update_guideline(existing, parsed, source)
  rescue ActiveRecord::RecordInvalid => e
    log "[WARN] Guideline #{external_data["name"]}, eid: #{external_data["id"]} cannot be updated. #{e.message}"
  rescue StandardError => e
    log "[WARN] Unexpected #{e}! Guideline #{external_data["name"]}, eid: #{external_data["id"]} cannot be updated"
  ensure
    log_status(existing, parsed)
  end

  not_modified = @request_guidelines.length - @created_count - @updated_count
  log "PROCESSED: #{@request_guidelines.length}, CREATED: #{@created_count}, UPDATED: #{@updated_count}, NOT MODIFIED: #{not_modified}"
end

def create_guideline(parsed, eid)
  guideline = Guideline.create!(parsed)
  GuidelineSource.create!(guideline: guideline, source_type: "eosc_registry", eid: eid)
  guideline.update_column(:upstream_id, guideline.sources.first.id)
end

def update_guideline(guideline, parsed, source)
  guideline.update!(parsed)
  # source already linked; nothing to do
end
```

### `connect_guidelines` — unchanged behaviour, updated field reference

V6 `public/resourceInteroperabilityRecord` sends `{resourceId, interoperabilityRecordIds}`. Current code works; only change: replace `Guideline.where(eid: [guideline_eids])` nesting bug:

```ruby
guidelines = Guideline.where(eid: guideline_eids) # remove nested array
```

### Validate

```bash
DRY_RUN=true bundle exec rake import:guidelines 2>&1 | tail -15
# Should show: "Adding [NEW] guideline: EOSC IF Guidelines for Data Sources..." with name (not title)
# No NoMethodError on `title`
# PROCESSED: 1 (per curl)
```

---

## H7. Service → Guideline view/helper updates (15 min)

Current references to `guideline.title` in app code:

```bash
rg -n "\\.title\\b" app/models/service.rb app/views/guidelines/ app/views/services/ 2>/dev/null | head
```

Replace each `guideline.title` with `guideline.name`. Small surface — Guideline has minimal UI.

### `app/serializers/ess/service_serializer.rb`

The `guidelines` attribute now serializes records with `name`. If ESS consumer expects `title`, add an alias:

```ruby
attribute :guidelines do
  object.guidelines.map do |g|
    { eid: g.eid, name: g.name, title: g.name, resource_type_general: g.resource_type_general }
  end
end
```

Flag as a schema change in Slice J notes.

---

## H8. Specs + fixture (30 min)

### `spec/services/importers/guideline_spec.rb` (new)

Fixture from the live V6 curl (see top of this file). Expect:

- `eid == "21.T15999/EnMoNU"`
- `name == "EOSC IF Guidelines..."`
- `resource_type == "InteroperabilityGuidelines"`
- `resource_type_general == "Guideline"`
- `resource_type_detail == "API"`
- `node_pid == "node-sandbox"`
- `resource_owner_pid == "21.T15999/vSRLQL"`
- `public_contact_emails == ["default@example.com"]`
- `related_standards.size == 5`
- `creators.first["firstName"] == "name"`
- `license_name.nil?` (API sent nothing)

### `spec/models/guideline_spec.rb`

- Validates `eid` uniqueness
- `resource_owner` returns `Provider` with matching PID (or nil)
- `node` returns `Vocabulary::Node` with matching EID (or nil)

### `spec/models/guideline_source_spec.rb` (new)

- Unique `(source_type, eid)` index enforced

### `spec/services/guideline/pc_create_or_update_spec.rb`

Update: `title` → `name` in assertions, expect full V6 field set.

### Validate

```bash
bundle exec rspec spec/models/guideline_spec.rb \
                  spec/models/guideline_source_spec.rb \
                  spec/services/importers/guideline_spec.rb \
                  spec/services/guideline/pc_create_or_update_spec.rb
```

---

## Validate (full slice)

```bash
# Schema
grep -A 25 'create_table "guidelines"' db/schema.rb | grep -cE "\b(name|description|publishing_date|resource_type|creators|node_pid|resource_owner_pid|public_contact_emails|related_standards|urls)\b"
# Should return 10+

# Model references use new names
rg -n "\\.title\\b" app/models/guideline.rb app/services/guideline/ app/services/importers/guideline.rb
# Should return empty

# JMS routing (added in Slice G)
grep -c 'when "guideline"' app/services/jms/manage_message.rb
# Should return 1

# Import dry-run against live V6
DRY_RUN=true bundle exec rake import:guidelines 2>&1 | tail -15
# Should log "Adding [NEW] guideline: EOSC IF Guidelines..."
```

**Commit.**

---

## Out of scope

- Backoffice UI for Guideline management (create/edit in UI). Guideline is import-only in V5; keeping that in V6. Ship in a follow-up if ops asks.
- Full-text search on guideline descriptions. Current setup does not Searchkick-index guidelines.
- Guideline versioning / `versionDate` field. V6 schema has `lastUpdate` concept — not seen in live record. Add when/if populated.
- Cross-entity interoperability records (Provider ↔ Guideline, Catalogue ↔ Guideline) — V6 spec mentions these but endpoint `public/resourceInteroperabilityRecord` currently only binds to resources (Services/Datasources). Scope stays the same as V5.
