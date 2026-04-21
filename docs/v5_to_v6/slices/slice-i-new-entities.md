# Slice I: New entity types — Adapter + TrainingResource (4d — **DEFERRABLE**)

Full stack for two V6 entity types that do not exist in V5. This slice can be deferred to a follow-up PR without blocking the rest of the migration. Slice G already reserves the topic names (D5) and ignores the JMS/AMS branches until this slice ships.

**Depends on Slice 0:** D5 (AMS topic names `mp-adapter-*`, `mp-training_resource-*`), D12 (new vocab types), D14 (alternativePIDs reuse `alternative_identifiers`), D15 (`urls` string array), D16 (nodePID as EID via `Array(...)` + `map_nodes`), D17 (`publicContacts` defensive parse), D18 (orchestrator suffix WITHOUT `/all`), **D24 (product scope decision — is this slice in this PR or a follow-up)**.

**Depends on Slice A:** `map_nodes`, `map_alternative_identifier`, `extract_public_contact_emails` helpers live in `Importable`. `Vocabulary::Node` kept, `TargetUser` kept (D8).

**Depends on Slice G:** The inbound topic aliases table (`INBOUND_TOPIC_ALIASES`) exists and routing is additive — Slice I just adds `when "adapter"` / `when "training_resource"` branches (pre-scaffolded in G2).

**Decision up-front:** per **D24**, if the product decision is to defer this slice for the migration PR, stop after reading this page and track the work as a follow-up issue. The rest of this document is the full spec for when it unblocks.

---

## I0. V6 API snapshot

### Adapter — `GET /api/public/adapter/all`

Top-level fields (from live payload):

```
id, name, urls (array|null), alternativePIDs (array|null), nodePID (string),
description, publishingDate (YYYY-MM-DD), type, resourceOwner (PID string),
linkedResource { resource_type, id }, tagline, logo, documentation,
repository, package (array), programmingLanguage (single EID string),
license, version, changeLog, lastUpdate (YYYY-MM-DD),
creators [ { firstName, lastName, email, role, PIDs, affiliations } ],
publicContacts (array — plain strings on this record, but defensive parse per D17),
sqa { sqaURL, sqaBadge }
```

Envelope shape: the endpoint returns `{ "total": N, "adapter": {...} }` PER RECORD — there is no `results` array wrapping; confirm against `Importers::Request#all` output before coding (see I6 orchestrator note).

### TrainingResource — `GET /api/public/trainingResource/all`

Live keys observed on a fully populated record:

```
accessRights, contentResourceTypes, creators, description, duration,
eoscRelatedServices, expertiseLevel, id, keywords, languages,
learningOutcomes, learningResourceTypes, name, nodePID, publicContacts,
publishingDate, qualifications, resourceOwner, scientificDomains,
targetGroups, type, versionDate
```

`qualifications` maps to the `TR_QUALIFICATION` vocab on D12's add list — store as string array. `license`, `urls`, and `alternativePIDs` are schema-allowed but absent on live records; producers omit when empty (D15 / D17). The importer's `parse_license` already returns `[nil, nil]` on missing input, and `Array(...)` handles the omitted arrays.

Schema to target (merging live observation with Athena spec for unpopulated fields):

```
id, name, description, publishingDate, type, nodePID, resourceOwner,
publicContacts, alternativePIDs (schema allows, absent on live), urls (schema allows, absent on live),
eoscRelatedServices (array of service PIDs), keywords (array of strings),
license (string or { name, url } — absent on live; keep parser, untested path),
accessRights (EID string — TR_ACCESS_RIGHT),
versionDate (YYYY-MM-DD), targetGroups (array of EIDs — TARGET_USER),
learningResourceTypes (array of EIDs — TR_DCMI_TYPE),
learningOutcomes (array of strings),
expertiseLevel (EID — TR_EXPERTISE_LEVEL),
contentResourceTypes (array of EIDs — TR_CONTENT_RESOURCE_TYPE),
qualifications (array of EIDs — TR_QUALIFICATION),
duration (string, e.g. "PT2H" ISO-8601 duration),
languages (array of EIDs — LANGUAGE),
scientificDomains [ { scientificDomain, scientificSubdomain } ],
creators (same shape as Adapter)
```

Re-curl before coding starts to catch any new fields on live records.

---

## I1. New vocabularies (45 min) — per D12

### ACCEPTED_VOCABULARIES — add to `lib/import/vocabularies.rb`

Append these entries (keep the existing 12 from Slice A):

```
ADAPTER_PROGRAMMING_LANGUAGE   # 50 items, eid prefix "adapter_programming_language-"
SPDX_LICENSE                   # 727 items, eid prefix "spdx_license-"
SQA_BADGE                      # 3 items, eid prefix "sqa_badge-"
CREDIT                         # 14 items — creator roles (eid prefix "credit-")
TR_ACCESS_RIGHT                # 4 items
TR_CONTENT_RESOURCE_TYPE       # 12 items
TR_DCMI_TYPE                   # 11 items
TR_EXPERTISE_LEVEL             # 4 items
TR_QUALIFICATION               # 3 items
LANGUAGE                       # 185 items
```

Total added: 10. `TARGET_USER` is already kept from Slice A per D8 — do not re-add.

### VOCABULARY_TYPES — add to `config/initializers/constants.rb`

Append (keeping the 10 from Slice A):

```ruby
adapter_programming_language: Vocabulary::AdapterProgrammingLanguage,
spdx_license:                 Vocabulary::SpdxLicense,
sqa_badge:                    Vocabulary::SqaBadge,
credit:                       Vocabulary::Credit,
tr_access_right:              Vocabulary::TrAccessRight,
tr_content_resource_type:     Vocabulary::TrContentResourceType,
tr_dcmi_type:                 Vocabulary::TrDcmiType,
tr_expertise_level:           Vocabulary::TrExpertiseLevel,
tr_qualification:             Vocabulary::TrQualification,
language:                     Vocabulary::Language
```

This auto-generates routes for `/vocabulary/adapter_programming_languages`, etc.

### New Vocabulary models

For each new key, create a file under `app/models/vocabulary/`:

```ruby
# app/models/vocabulary/adapter_programming_language.rb
class Vocabulary::AdapterProgrammingLanguage < Vocabulary
end

# app/models/vocabulary/spdx_license.rb
class Vocabulary::SpdxLicense < Vocabulary
end
# ... same STI pattern for: SqaBadge, Credit, TrAccessRight,
# TrContentResourceType, TrDcmiType, TrExpertiseLevel, TrQualification, Language
```

One class per file, empty body — they are STI subclasses of `Vocabulary`.

### Validate I1

```bash
bundle exec rails runner '
  %w[Vocabulary::AdapterProgrammingLanguage Vocabulary::SpdxLicense Vocabulary::SqaBadge
     Vocabulary::Credit Vocabulary::TrAccessRight Vocabulary::TrContentResourceType
     Vocabulary::TrDcmiType Vocabulary::TrExpertiseLevel Vocabulary::TrQualification
     Vocabulary::Language].each { |k| puts "#{k}: #{k.constantize.ancestors.first}" }
'
# Every line should print the class name.

DRY_RUN=true bundle exec rake import:vocabularies 2>&1 | grep -E "(ADAPTER_PROGRAMMING_LANGUAGE|SPDX_LICENSE|TR_DCMI_TYPE|LANGUAGE)"
# Should show all 10 being fetched.
```

---

## I2. Adapter DB migration (45 min)

**File:** `db/migrate/YYYYMMDDHHMMSS_create_adapters.rb`

```ruby
class CreateAdapters < ActiveRecord::Migration[7.2]
  def change
    create_table :adapters do |t|
      # Identity + lifecycle
      t.string :pid # V6 "id"
      t.string :name, null: false
      t.string :tagline
      t.string :description
      t.date :publishing_date
      t.date :last_update

      # Relationships (stored as EIDs; model looks up at runtime — matches Guideline pattern per Slice H)
      t.string :resource_owner_pid # resourceOwner (Provider EID)
      t.string :node_pid # nodePID (Vocabulary::Node EID) per D16
      t.string :linked_resource_type # e.g. "interoperability_record"
      t.string :linked_resource_eid # id inside linkedResource

      # Repo / docs / packaging
      t.string :documentation
      t.string :repository
      t.string :change_log
      t.string :package, array: true, default: []
      t.string :urls, array: true, default: [] # D15
      t.string :version

      # License — may be plain string or { name, url } — store both defensively
      t.string :license_name # if object: license["name"]; else the raw string
      t.string :license_url # if object: license["url"]; else nil

      # SQA
      t.string :sqa_url
      t.string :sqa_badge # Vocabulary::SqaBadge EID

      # Programming language — single EID (NOT an array, per live payload)
      t.string :programming_language # Vocabulary::AdapterProgrammingLanguage EID

      # Creators — jsonb, matches Slice H Guideline `creators` pattern
      t.jsonb :creators, default: []

      # Emails — defensive per D17
      t.string :public_contact_emails, array: true, default: []

      # Logo via Active Storage (attached by Importers::Logo — no column)

      # Lifecycle / upstream — mirrors DeployableService exactly
      t.string :status, default: "draft", null: false
      t.bigint :upstream_id
      t.string :ppid # extracted from alternativePIDs per D14 (same helper as Provider)
      t.integer :synchronized_at, limit: 8

      t.timestamps
    end

    add_index :adapters, :pid, unique: true
    add_index :adapters, :resource_owner_pid
    add_index :adapters, :node_pid

    # alternativePIDs join (reuse `alternative_identifiers` table per D14)
    create_table :adapter_alternative_identifiers do |t|
      t.references :adapter, null: false, foreign_key: true
      t.references :alternative_identifier, null: false, foreign_key: true
      t.timestamps
    end
  end
end
```

**Notes:**

- No `catalogue_id` — Adapter is not scoped to a catalogue in V6.
- `resource_owner_pid` / `node_pid` store the raw EID. The model exposes `resource_owner` / `node` helpers that do the lookup — same pattern as Slice H Guideline (avoids circular FK + keeps importer simple when the Provider hasn't imported yet).

### Validate I2

```bash
rails db:migrate
grep -A 30 'create_table "adapters"' db/schema.rb | grep -cE "(pid|name|urls|creators|public_contact_emails|sqa_badge)"
# Should return ≥ 6
```

---

## I3. Adapter model + source model (30 min)

**File:** `app/models/adapter.rb`

```ruby
class Adapter < ApplicationRecord
  include Publishable # draft → published workflow
  include LogoAttachable # Active Storage logo

  has_many :sources, class_name: "AdapterSource", dependent: :destroy, inverse_of: :adapter
  has_many :adapter_alternative_identifiers, dependent: :destroy
  has_many :alternative_identifiers, through: :adapter_alternative_identifiers # D14

  accepts_nested_attributes_for :alternative_identifiers, allow_destroy: true
  accepts_nested_attributes_for :sources, allow_destroy: true

  validates :name, presence: true
  validates :pid, presence: true, uniqueness: true

  # Lookups — same pattern as Guideline (Slice H)
  def resource_owner
    Provider.find_by(pid: resource_owner_pid) if resource_owner_pid.present?
  end

  def node
    Vocabulary::Node.find_by(eid: node_pid) if node_pid.present?
  end

  def programming_language_vocab
    Vocabulary::AdapterProgrammingLanguage.find_by(eid: programming_language) if programming_language.present?
  end

  def sqa_badge_vocab
    Vocabulary::SqaBadge.find_by(eid: sqa_badge) if sqa_badge.present?
  end

  def logo_url
    "#{host_url}#{Rails.application.routes.url_helpers.rails_blob_path(logo, only_path: true)}" if logo.attached?
  end

  # Slice G G7 outbound topic override (only needed if MP publishes adapter events back)
  def publish_topic_name
    "adapter"
  end
end
```

**File:** `app/models/adapter_source.rb`

```ruby
class AdapterSource < ApplicationRecord
  enum :source_type, { eosc_registry: "eosc_registry" }
  belongs_to :adapter, inverse_of: :sources

  validates :eid, presence: true
  validates :source_type, presence: true

  def to_s
    "#{source_type}: #{eid}"
  end
end
```

**File:** `db/migrate/YYYYMMDDHHMMSS_create_adapter_sources.rb`

```ruby
class CreateAdapterSources < ActiveRecord::Migration[7.2]
  def change
    create_table :adapter_sources do |t|
      t.references :adapter, null: false, foreign_key: true
      t.string :source_type, null: false
      t.string :eid, null: false
      t.jsonb :errored
      t.timestamps
    end
    add_index :adapter_sources, %i[source_type eid], unique: true
  end
end
```

**Do NOT include** `Propagable` unless MP publishes adapter events upstream. If unsure, skip — importer-only flow is the common case, matches DeployableService's current state.

---

## I4. Adapter importer (45 min)

**File:** `app/services/importers/adapter.rb`

```ruby
class Importers::Adapter < ApplicationService
  include Importable

  def initialize(data, synchronized_at)
    super()
    @data = data
    @synchronized_at = synchronized_at
  end

  def call
    alt_pids = Array(@data["alternativePIDs"])
    license_name, license_url = parse_license(@data["license"])

    {
      pid: @data["id"],
      name: @data["name"],
      tagline: @data["tagline"] || "",
      description: @data["description"] || "",
      publishing_date: parse_date(@data["publishingDate"]),
      last_update: parse_date(@data["lastUpdate"]),
      resource_owner_pid: @data["resourceOwner"],
      node_pid: @data["nodePID"], # D16 — single EID string
      linked_resource_type: @data.dig("linkedResource", "resource_type"),
      linked_resource_eid: @data.dig("linkedResource", "id"),
      documentation: @data["documentation"],
      repository: @data["repository"],
      change_log: @data["changeLog"],
      package: Array(@data["package"]),
      urls: Array(@data["urls"]), # D15
      version: @data["version"],
      license_name: license_name,
      license_url: license_url,
      sqa_url: @data.dig("sqa", "sqaURL"),
      sqa_badge: @data.dig("sqa", "sqaBadge"),
      programming_language: @data["programmingLanguage"], # single EID per live API — NOT an array
      creators: Array(@data["creators"]), # stored as jsonb verbatim
      public_contact_emails: extract_public_contact_emails(@data["publicContacts"]), # D17
      alternative_identifiers: alt_pids.map { |p| map_alternative_identifier(p) }.compact, # D14
      ppid: fetch_ppid(alt_pids),
      synchronized_at: @synchronized_at,
      status: :published
    }
  end

  private

  def parse_date(raw)
    return nil if raw.blank?
    Date.parse(raw)
  rescue ArgumentError
    nil
  end

  def parse_license(raw)
    return nil, nil if raw.blank?
    return raw["name"], raw["url"] if raw.is_a?(Hash)
    [raw.to_s, nil]
  end
end
```

### Helpers referenced

- `extract_public_contact_emails` — added to `Importable` in Slice A2.
- `map_alternative_identifier` — existing in `Importable`, handles `{pid, pidSchema}` mapping per D14.
- `fetch_ppid` — existing in `Importable`, pulls the PPID-flagged entry out of `alternativePIDs`.

No new helpers needed in `Importable`.

### Validate I4

```bash
bundle exec rspec spec/services/importers/adapter_spec.rb
```

---

## I5. Adapter `PcCreateOrUpdate` service + jobs (20 min)

**File:** `app/services/adapter/pc_create_or_update.rb`

Mirror `app/services/guideline/pc_create_or_update.rb` (Slice H5):

```ruby
class Adapter::PcCreateOrUpdate < ApplicationService
  def initialize(data, status, synchronized_at)
    super()
    @data = data
    @status = status
    @synchronized_at = synchronized_at
  end

  def call
    parsed = Importers::Adapter.call(@data, @synchronized_at)
    parsed[:status] = @status

    eid = @data["id"]
    source = AdapterSource.find_by(source_type: "eosc_registry", eid: eid)
    adapter = source&.adapter || Adapter.find_by(pid: parsed[:pid])

    if adapter.nil?
      adapter = Adapter.new(parsed)
      adapter.save(validate: false)
      source = AdapterSource.create!(adapter_id: adapter.id, source_type: "eosc_registry", eid: eid)
      adapter.update(upstream_id: source.id)
      Importers::Logo.call(adapter, @data["logo"]) if @data["logo"].present?
      adapter.save(validate: false)
    elsif source.present? && source.id == adapter.upstream_id
      adapter.update(parsed)
      Importers::Logo.call(adapter, @data["logo"]) if @data["logo"].present?
      adapter.save!
    end

    adapter
  end
end
```

**File:** `app/jobs/adapter/pc_create_or_update_job.rb`

```ruby
class Adapter::PcCreateOrUpdateJob < ApplicationJob
  queue_as :pc_subscriber

  def perform(data, status, synchronized_at)
    Adapter::PcCreateOrUpdate.call(data, status, synchronized_at)
  end
end
```

**File:** `app/jobs/adapter/delete_job.rb`

```ruby
class Adapter::DeleteJob < ApplicationJob
  queue_as :pc_subscriber

  def perform(pid)
    Adapter.find_by(pid: pid)&.destroy
  end
end
```

---

## I6. Adapter batch import orchestrator (45 min)

**File:** `lib/import/adapters.rb`

Structure mirrors `lib/import/deployable_services.rb` exactly. Key points:

- Suffix passed to `Importers::Request.new` is **`"public/adapter"`** (no `/all`) per D18. `Importers::Request#all` appends `/all?quantity=10000&from=0`.
- Envelope: check `rp.body["results"]` first. The live endpoint wraps each record under an `"adapter"` key (see I0), so unwrap with `.map { |r| r["adapter"] || r }` — matches the Provider pattern of `external_data["provider"]`.

```ruby
# frozen_string_literal: true

class Import::Adapters
  include Importable

  def initialize(
    eosc_registry_base_url,
    dry_run: true,
    filepath: nil,
    faraday: Faraday,
    logger: ->(msg) { puts msg },
    ids: [],
    default_upstream: :eosc_registry,
    token: nil,
    rescue_mode: false
  )
    super()
    @eosc_registry_base_url = eosc_registry_base_url
    @dry_run = dry_run
    @faraday = faraday
    @default_upstream = default_upstream
    @token = token
    @rescue_mode = rescue_mode
    @ids = ids
    @logger = logger
    @filepath = filepath
    @updated_count = 0
    @created_count = 0
  end

  def call
    log "Importing adapters from EOSC Registry #{@eosc_registry_base_url}..."
    @request_adapters = external_adapters_data.select { |a| @ids.empty? || @ids.include?(a["id"]) }

    @request_adapters.each do |external_data|
      eid = external_data["id"]
      parsed = Importers::Adapter.call(external_data, Time.now.to_i)
      parsed["status"] = object_status(external_data["active"], external_data["suspended"]) if external_data.key?(
        "active"
      )

      source = AdapterSource.find_by(source_type: "eosc_registry", eid: eid)
      current = (source && Adapter.find_by(id: source.adapter_id)) || Adapter.find_by(pid: parsed[:pid])

      next if @dry_run

      if current.blank?
        create_adapter(parsed, external_data["logo"], eid)
      elsif source.present? && source.id == current.upstream_id
        update_adapter(current, parsed, external_data["logo"])
      end
    rescue ActiveRecord::RecordInvalid
      log "[WARN] Adapter #{external_data["name"]}, eid: #{eid} cannot be updated. #{current&.errors&.full_messages}"
    rescue StandardError => e
      log "[WARN] Unexpected #{e}! Adapter #{external_data["name"]}, eid: #{eid} cannot be updated"
    ensure
      log_status(current, parsed, source)
    end

    not_modified = @request_adapters.length - @created_count - @updated_count
    log "PROCESSED: #{@request_adapters.length}, CREATED: #{@created_count}, " \
          "UPDATED: #{@updated_count}, NOT MODIFIED: #{not_modified}"

    File.open(@filepath, "w") { |f| f << JSON.pretty_generate(@request_adapters) } unless @filepath.nil?
  end

  private

  def external_adapters_data
    @token ||= Importers::Token.new(faraday: @faraday).receive_token
    rp = Importers::Request.new(@eosc_registry_base_url, "public/adapter", faraday: @faraday, token: @token).call
    Array(rp.body["results"]).map { |r| r.is_a?(Hash) && r.key?("adapter") ? r["adapter"] : r }
  rescue Errno::ECONNREFUSED, Importers::Token::RequestError => e
    abort("import exited with errors - could not connect to #{@eosc_registry_base_url} \n #{e.message}")
  end

  def create_adapter(parsed, logo_url, eid)
    adapter = Adapter.new(parsed)
    adapter.save(validate: false)
    source = AdapterSource.create!(adapter_id: adapter.id, source_type: "eosc_registry", eid: eid)
    adapter.upstream_id = source.id
    Importers::Logo.call(adapter, logo_url) unless @rescue_mode
    adapter.save(validate: false)
  end

  def update_adapter(adapter, parsed, logo_url)
    adapter.update(parsed)
    Importers::Logo.call(adapter, logo_url) unless @rescue_mode
    adapter.save!
  end

  def log_status(adapter, parsed, source)
    if adapter.blank?
      @created_count += 1
      log "Adding [NEW] adapter: #{parsed[:name]}, eid: #{parsed[:pid]}"
    elsif source.present? && source.id == adapter.upstream_id
      @updated_count += 1
      log "Updating [EXISTING] adapter: #{parsed[:name]}, eid: #{parsed[:pid]}"
    end
  end

  def log(msg) = @logger.call(msg)
end
```

**Rake task** — append to `lib/tasks/import.rake`:

```ruby
namespace :import do
  desc "Import adapters from EOSC Registry"
  task adapters: :environment do
    Import::Adapters.new(
      ENV["MP_IMPORT_EOSC_REGISTRY_URL"],
      dry_run: ENV["DRY_RUN"] == "true",
      ids: (ENV["IDS"] || "").split(",")
    ).call
  end
end
```

### Validate I6

```bash
DRY_RUN=true bundle exec rake import:adapters 2>&1 | tail -10
# "PROCESSED: 1, CREATED: ..." — no 404, no NameError
```

---

## I7. Adapter JMS / AMS routing (10 min)

Already scaffolded in Slice G2. Un-comment the branches:

```ruby
# app/services/ams/manage_message.rb — already written in Slice G2, just remove the "only if Slice I ships" guard
when "adapter"
  modified_at = modified_at(body)
  case action
  when "delete"
    Adapter::DeleteJob.perform_later(resource["id"])
  else
    Adapter::PcCreateOrUpdateJob.perform_later(
      resource, object_status(body["active"], body["suspended"]), modified_at
    )
  end
```

Add the SAME branch to `app/services/jms/manage_message.rb` (Slice G1 handles JMS but only adds adapter when Slice I ships).

Add to `config/ams_subscriber.yml` (Slice G3 left these commented out):

```yaml
- mp-adapter-create
- mp-adapter-delete
- mp-adapter-update
```

### Validate I7

```bash
grep -cE 'when "adapter"' app/services/jms/manage_message.rb app/services/ams/manage_message.rb
# Should return 2 (1 hit per file)

grep -cE "mp-adapter-(create|delete|update)" config/ams_subscriber.yml
# Should return 3
```

---

## I8. Adapter ESS serializer (20 min) — only if ESS consumes adapters

Check with Athena whether ESS/search indexes adapters. Default: yes (every top-level entity is indexed). Mirror `ess/service_serializer.rb`.

**File:** `app/serializers/ess/adapter_serializer.rb`

```ruby
class Ess::AdapterSerializer < ApplicationRecord::Serializer
  attributes :id,
             :pid,
             :name,
             :description,
             :tagline,
             :urls,
             :package,
             :documentation,
             :repository,
             :change_log,
             :version,
             :publishing_date,
             :last_update,
             :resource_owner_pid,
             :node_pid,
             :programming_language,
             :sqa_url,
             :sqa_badge,
             :license_name,
             :license_url,
             :public_contact_emails,
             :alternative_pids,
             :creators,
             :logo_url

  def alternative_pids
    object.alternative_identifiers.map { |a| { pid: a.value, pid_schema: a.identifier_type } }
  end
end
```

If the `Propagable` concern is NOT added to the Adapter model (see I3 note), manual reindex is still possible via `Adapter.find_each { |a| Ess::Add.call(a) }` in the rake task.

---

## I9. Adapter backoffice views + policy (2h — OPTIONAL)

**Default: SKIP.** Adapter is import-only from the PC. No backoffice create/edit form in this migration. Add show pages only if the product requires operators to view adapter details in the backoffice.

If shipping show-only views:

- `app/views/backoffice/adapters/index.html.haml` — table of adapters (`name`, `pid`, `resource_owner`, `status`, `synchronized_at`)
- `app/views/backoffice/adapters/show.html.haml` — read-only detail
- `app/controllers/backoffice/adapters_controller.rb` — `index` / `show` actions only
- `app/policies/backoffice/adapter_policy.rb` — `index?` / `show?` (admin-only)
- Route: `resources :adapters, only: [:index, :show]` inside the `backoffice` namespace

No wizard, no params permitted list — users cannot create adapters from the MP UI.

---

## I10. Adapter specs (30 min)

```
spec/models/adapter_spec.rb                     # associations, validations, lookup methods
spec/models/adapter_source_spec.rb              # basic CRUD
spec/services/importers/adapter_spec.rb         # use fixture, assert every field mapping
spec/services/adapter/pc_create_or_update_spec.rb
spec/jobs/adapter/pc_create_or_update_job_spec.rb
spec/lib/import/adapters_spec.rb                # stub Importers::Request, assert counts
spec/factories/adapters.rb
spec/factories/adapter_sources.rb
```

**Fixture:** copy the live record captured in I0 into `spec/fixtures/adapter_v6.json` verbatim.

**Assertions in `importers/adapter_spec.rb`** (one per V6 field — non-exhaustive):

```ruby
it { expect(result[:pid]).to eq "21.T15999/GduT2v" }
it { expect(result[:node_pid]).to eq "node-sandbox" }
it { expect(result[:programming_language]).to eq "adapter_programming_language-abap" }
it { expect(result[:sqa_badge]).to eq "sqa_badge-bronze" }
it { expect(result[:public_contact_emails]).to eq ["a@gmail.com"] }
it { expect(result[:creators]).to be_an Array }
it { expect(result[:urls]).to eq [] } # null in V6 → [] via Array()
it { expect(result[:package]).to eq ["https://www.google.com"] }
it { expect(result[:linked_resource_type]).to eq "interoperability_record" }
```

### Validate I10

```bash
bundle exec rspec spec/models/adapter_spec.rb spec/services/importers/adapter_spec.rb \
                  spec/services/adapter/pc_create_or_update_spec.rb \
                  spec/jobs/adapter/pc_create_or_update_job_spec.rb \
                  spec/lib/import/adapters_spec.rb
# Should pass with 0 failures.
```

**Commit: Adapter end-to-end.**

---

## I11. TrainingResource — full stack (2d)

Execute the same 10-step pattern as Adapter, substituting TR fields. Only differences documented below — everything else (model source pair, PcCreateOrUpdate service + jobs, AMS/JMS branches, orchestrator, specs) is structurally identical.

### I11a. TrainingResource DB migration

**File:** `db/migrate/YYYYMMDDHHMMSS_create_training_resources.rb`

```ruby
class CreateTrainingResources < ActiveRecord::Migration[7.2]
  def change
    create_table :training_resources do |t|
      t.string :pid
      t.string :name, null: false
      t.string :description
      t.date :publishing_date
      t.date :version_date
      t.string :resource_owner_pid
      t.string :node_pid # D16
      t.string :urls, array: true, default: [] # D15
      t.string :keywords, array: true, default: []
      t.string :license
      t.string :access_right # Vocabulary::TrAccessRight EID
      t.string :expertise_level # Vocabulary::TrExpertiseLevel EID
      t.string :target_groups, array: true, default: [] # TargetUser EIDs
      t.string :learning_resource_types, array: true, default: [] # TrDcmiType EIDs
      t.string :content_resource_types, array: true, default: [] # TrContentResourceType EIDs
      t.string :qualifications, array: true, default: [] # TrQualification EIDs
      t.string :languages, array: true, default: [] # Language EIDs
      t.string :eosc_related_services, array: true, default: [] # Service PIDs
      t.text :learning_outcomes # stored as \n-joined text
      t.string :duration # ISO 8601 duration string (verbatim)
      t.jsonb :creators, default: []
      t.string :public_contact_emails, array: true, default: []
      t.string :status, default: "draft", null: false
      t.bigint :upstream_id
      t.string :ppid
      t.integer :synchronized_at, limit: 8
      t.timestamps
    end
    add_index :training_resources, :pid, unique: true

    # scientificDomains — reuse existing polymorphic pattern or add dedicated join
    create_table :training_resource_scientific_domains do |t|
      t.references :training_resource, null: false, foreign_key: true
      t.references :scientific_domain, null: false, foreign_key: true
      t.timestamps
    end

    # alternativePIDs — D14
    create_table :training_resource_alternative_identifiers do |t|
      t.references :training_resource, null: false, foreign_key: true
      t.references :alternative_identifier, null: false, foreign_key: true
      t.timestamps
    end
  end
end
```

**Notes:**

- `access_right`, `expertise_level`, `duration`, `license` are stored as single strings (EIDs or verbatim). Model exposes `*_vocab` lookups for the vocabulary ones — same pattern as Adapter (I3).
- `target_groups` — the V6 API key is `targetGroups` but the values are `TARGET_USER` vocabulary EIDs (Slice 0 D8 keeps `TargetUser` specifically for this).
- `scientificDomains` reuses the existing `scientific_domains` table via a new join. No new vocabulary imports needed.

### I11b. TrainingResource model

```ruby
# app/models/training_resource.rb
class TrainingResource < ApplicationRecord
  include Publishable
  include LogoAttachable

  has_many :sources, class_name: "TrainingResourceSource", dependent: :destroy, inverse_of: :training_resource
  has_many :training_resource_scientific_domains, dependent: :destroy
  has_many :scientific_domains, through: :training_resource_scientific_domains
  has_many :training_resource_alternative_identifiers, dependent: :destroy
  has_many :alternative_identifiers, through: :training_resource_alternative_identifiers

  accepts_nested_attributes_for :alternative_identifiers, allow_destroy: true
  accepts_nested_attributes_for :scientific_domains, allow_destroy: true

  validates :name, presence: true
  validates :pid, presence: true, uniqueness: true

  def resource_owner = Provider.find_by(pid: resource_owner_pid) if resource_owner_pid.present?
  def node = Vocabulary::Node.find_by(eid: node_pid) if node_pid.present?
  def access_right_vocab = Vocabulary::TrAccessRight.find_by(eid: access_right) if access_right.present?
  def expertise_level_vocab = Vocabulary::TrExpertiseLevel.find_by(eid: expertise_level) if expertise_level.present?
  def target_user_vocabs = TargetUser.where(eid: Array(target_groups))
  def language_vocabs = Vocabulary::Language.where(eid: Array(languages))
  def qualification_vocabs = Vocabulary::TrQualification.where(eid: Array(qualifications))

  def publish_topic_name = "training_resource"
end
```

`TrainingResourceSource` mirrors `AdapterSource` — copy that file, rename class + FK.

### I11c. TrainingResource importer

**File:** `app/services/importers/training_resource.rb`

```ruby
class Importers::TrainingResource < ApplicationService
  include Importable

  def initialize(data, synchronized_at)
    super()
    @data = data
    @synchronized_at = synchronized_at
  end

  def call
    alt_pids = Array(@data["alternativePIDs"])
    scientific_subdomain_eids = Array(@data["scientificDomains"]).map { |sd| sd["scientificSubdomain"] }

    {
      pid: @data["id"],
      name: @data["name"],
      description: @data["description"] || "",
      publishing_date: parse_date(@data["publishingDate"]),
      version_date: parse_date(@data["versionDate"]),
      resource_owner_pid: @data["resourceOwner"],
      node_pid: @data["nodePID"], # D16
      urls: Array(@data["urls"]), # D15
      keywords: Array(@data["keywords"]),
      license: parse_license(@data["license"]),
      access_right: @data["accessRights"],
      expertise_level: @data["expertiseLevel"],
      target_groups: Array(@data["targetGroups"]),
      learning_resource_types: Array(@data["learningResourceTypes"]),
      content_resource_types: Array(@data["contentResourceTypes"]),
      qualifications: Array(@data["qualifications"]),
      languages: Array(@data["languages"]),
      eosc_related_services: Array(@data["eoscRelatedServices"]),
      learning_outcomes: Array(@data["learningOutcomes"]).join("\n"),
      duration: @data["duration"],
      creators: Array(@data["creators"]),
      scientific_domains: map_scientific_domains(scientific_subdomain_eids),
      public_contact_emails: extract_public_contact_emails(@data["publicContacts"]), # D17
      alternative_identifiers: alt_pids.map { |p| map_alternative_identifier(p) }.compact, # D14
      ppid: fetch_ppid(alt_pids),
      synchronized_at: @synchronized_at,
      status: :published
    }
  end

  private

  def parse_date(raw)
    return nil if raw.blank?
    Date.parse(raw)
  rescue ArgumentError
    nil
  end

  def parse_license(raw)
    return nil if raw.blank?
    return raw["name"] if raw.is_a?(Hash)
    raw.to_s
  end
end
```

### I11d. TrainingResource jobs + orchestrator

Copy `app/jobs/adapter/pc_create_or_update_job.rb`, `app/jobs/adapter/delete_job.rb`, `app/services/adapter/pc_create_or_update.rb`, and `lib/import/adapters.rb` — rename `Adapter` → `TrainingResource` throughout. Suffix in orchestrator: `"public/trainingResource"` (per D18, no `/all`). Envelope: verify once a real record exists — if wrapped under `"trainingResource"`, unwrap the same way as Adapter in I6.

**Rake task** — append:

```ruby
namespace :import do
  desc "Import training resources from EOSC Registry"
  task training_resources: :environment do
    Import::TrainingResources.new(
      ENV["MP_IMPORT_EOSC_REGISTRY_URL"],
      dry_run: ENV["DRY_RUN"] == "true",
      ids: (ENV["IDS"] || "").split(",")
    ).call
  end
end
```

### I11e. TrainingResource JMS/AMS routing

Same as I7, substitute `adapter` → `training_resource`. Add branches in both `jms/manage_message.rb` and `ams/manage_message.rb`; add three entries to `config/ams_subscriber.yml`.

### I11f. TrainingResource ESS serializer

Mirror `Ess::AdapterSerializer`. Attributes list:

```
id, pid, name, description, urls, keywords, access_right, expertise_level,
target_groups, learning_resource_types, content_resource_types, qualifications,
languages, learning_outcomes, duration, license, resource_owner_pid, node_pid,
public_contact_emails, alternative_pids, eosc_related_services, creators,
scientific_domain_ids, logo_url
```

### I11g. TrainingResource specs

Same file list as I10 under `training_resource` namespace. Fixture path: `spec/fixtures/training_resource_v6.json`. Curl `/public/trainingResource/all?quantity=10&from=0` against the target env (prefer dev when populated, fall back to integration) and snapshot a real record as the fixture rather than synthesising.

### Validate I11 (full)

```bash
test -f app/models/training_resource.rb \
  && test -f app/services/importers/training_resource.rb \
  && test -f app/services/training_resource/pc_create_or_update.rb \
  && test -f lib/import/training_resources.rb && echo "OK"

DRY_RUN=true bundle exec rake import:training_resources 2>&1 | tail -5
# Expect a PROCESSED line, no crash.

bundle exec rspec spec/models/training_resource_spec.rb \
                  spec/services/importers/training_resource_spec.rb \
                  spec/lib/import/training_resources_spec.rb
```

**Commit: TrainingResource end-to-end.**

---

## Slice I close-out checklist

- [ ] All 10 new vocabularies imported (`bundle exec rake import:vocabularies` lists them).
- [ ] `Adapter` and `TrainingResource` models + source models exist and boot (`Rails.application.eager_load!`).
- [ ] `Importers::Adapter` / `Importers::TrainingResource` specs green with real / synthesised fixtures.
- [ ] `Adapter::PcCreateOrUpdateJob` and `TrainingResource::PcCreateOrUpdateJob` enqueue successfully via rspec job specs.
- [ ] Both entities routed from JMS AND AMS (grep the aliases table).
- [ ] `config/ams_subscriber.yml` lists all six `mp-adapter-*` / `mp-training_resource-*` topics.
- [ ] Dry-run import tasks complete without exceptions on staging env URL.
- [ ] No existing Provider / Service specs regressed (`bundle exec rspec spec/models/ spec/services/ --format progress`).
- [ ] README.md open-questions list: mark D5 and D12 as resolved.

If either sub-slice cannot ship (e.g., AMS topics for one side are not confirmed), ship the other. The two entities are independent — the only shared work is I1 (vocabularies), which can ship alone as a prep PR if needed.
