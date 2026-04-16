# Slice C: Service end-to-end (2.5d)

Service is the most complex entity. Same shape as Provider but wider, plus Elasticsearch/Searchkick changes and a facet cleanup in the public search API.

**Depends on Slice 0 decisions:** D3 (drop removed data), D6 (keep `acts_as_taggable`), D13 (`accessTypes` is an array on Service — integration returns `["access_type-physical", "access_type-remote"]`; `Array()` wrap is still required because Datasource returns a singular string), D14 (reuse `alternative_identifiers` for `alternativePIDs`), D15 (`urls` column — field omitted when empty, importer must tolerate missing key), D16 (`nodePID` = EID, wrap in `Array()`), D17 (`publicContacts` is an array of plain strings — helper's hash branch is defensive dead code), D18 (`Importers::Request` URL bug — suffix is `public/service`, NOT `public/service/all`).

**Depends on Slice A:** `Importable` helpers removed / renamed in A2, vocabulary classes dropped in A1. Do NOT start Slice C until Slice A is merged, or the importer will reference classes that no longer exist.

---

## C1. Data migration — contacts → emails, archive V5 rows (20 min)

**File:** `db/migrate/YYYYMMDDHHMMSS_migrate_service_contacts_to_emails.rb`

This migration MUST run before C2 (which drops the columns/join tables that this migration reads from).

```ruby
class MigrateServiceContactsToEmails < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def up
    add_column :services, :public_contact_emails, :string, array: true, default: []

    Service.reset_column_information
    Service.unscoped.find_each do |s|
      emails =
        PublicContact
          .where(contactable_type: "Service", contactable_id: s.id)
          .pluck(:email)
          .compact
          .map(&:strip)
          .reject(&:empty?)
          .uniq
      next if emails.empty?
      s.update_columns(public_contact_emails: emails)
    end
  end

  def down
    remove_column :services, :public_contact_emails
  end
end
```

### Archive (optional, controlled by D3)

If operator sets `ARCHIVE=true`, dump the V5-only Service rows (columns listed in C2 "Columns to REMOVE") to `tmp/v5_archive_services_YYYYMMDD.json`. The `rake db:v5_archive` task introduced in Slice B handles Services too — add a `Service.unscoped.find_each` block to that task.

### Validate

```bash
rails db:migrate
rails runner 'puts Service.where.not(public_contact_emails: []).count'
# Should roughly match `rails runner "puts PublicContact.where(contactable_type: %q(Service)).distinct.pluck(:contactable_id).count"` before migration
```

---

## C2. DB migration — strip service table, drop joins, add V6 columns (45 min)

**File:** `db/migrate/YYYYMMDDHHMMSS_strip_service_to_v6.rb`

### Columns to REMOVE from `services`

```
tagline                        (text, null: false)
geographical_availabilities    (string[], default: [])
language_availability          (string[], default: [])
resource_geographic_locations  (string[], default: [])
dedicated_for                  (string[])              # legacy alias for target_users
helpdesk_url                   (string)
manual_url                     (string)
training_information_url       (string)
status_monitoring_url          (string)
maintenance_url                (string)
resource_level_url             (string)
helpdesk_email                 (string, default: "")
security_contact_email         (string, default: "", null: false)
payment_model_url              (string)
pricing_url                    (string)
certifications                 (string[], default: [])
standards                      (string[], default: [])
open_source_technologies       (string[], default: [])
changelog                      (text[], default: [])
grant_project_names            (string[], default: [])
related_platforms              (string[], default: [])
version                        (string)
last_update                    (datetime)
restrictions                   (string)
activate_message               (text)
horizontal                     (boolean, default: false, null: false)
abbreviation                   (string)
availability_cache             (float)
reliability_cache              (float)
provider_id                    (bigint)                # legacy FK, superseded by resource_organisation_id
```

### Columns to KEEP (V6-compatible or MP-internal)

```
id, name, description, webpage_url, slug, pid, ppid, type, status, upstream_id,
synchronized_at, created_at, updated_at, logo (Active Storage, separate table),
rating, service_opinion_count, project_items_count, offers_count, bundles_count,
usage_counts_views, popularity_ratio, resource_organisation_id,
order_type (null: false), order_url (default: ""), terms_of_use_url,
access_policies_url, privacy_policy_url
```

### Datasource-STI columns

Leave untouched in Slice C — Slice D reshapes them:
`submission_policy_url`, `preservation_policy_url`, `jurisdiction_id`,
`datasource_classification_id`, `version_control`, `thematic`, `datasource_id`,
`harvestable`.

### Columns to ADD

```
publishing_date :date
resource_type   :string
urls            :string, array: true, default: []   # D15
```

### Join tables to drop (polymorphic `service_vocabularies` rows) — in same migration

Delete all `service_vocabularies` rows where `vocabulary_type` matches these, then (optionally) re-check `service_vocabularies` still has remaining rows for the kept types:

```ruby
execute <<~SQL
  DELETE FROM service_vocabularies
  WHERE vocabulary_type IN (
    'Vocabulary::AccessMode',
    'Vocabulary::FundingBody',
    'Vocabulary::FundingProgram',
    'Vocabulary::LifeCycleStatus',
    'Vocabulary::MarketplaceLocation',
    'Vocabulary::ServiceCategory',
    'Vocabulary::EntityType',
    'Vocabulary::ResearchProductAccessPolicy',
    'Vocabulary::ResearchProductMetadataAccessPolicy'
  );
SQL
```

`EntityType`, `ResearchProductAccessPolicy`, `ResearchProductMetadataAccessPolicy`
are cleaned up here so Slice D can focus on `persistent_identity_systems` and
PID-system struct changes.

Kept vocabulary sources on Service: `Vocabulary::Trl`, `Vocabulary::AccessType`, `Vocabulary::Node`, `Vocabulary::Jurisdiction` (via `jurisdiction_id`).

### Tables to drop entirely (Service-only joins)

```ruby
drop_table :service_target_users # D8 — TargetUser model stays for TrainingResource, join goes (NOTE: also dropped in A6 — `if_exists: true` makes this safe)
drop_table :service_related_platforms # related_platforms column also gone (also dropped in A6 — safe duplicate)
drop_table :service_catalogues # if you confirm `service_catalogue` association unused in V6
drop_table :service_relationships # related_services / required_services / manual_related_services (also dropped in A6 — safe duplicate)
```

Keep before dropping `service_catalogues`: confirm with `git grep has_one :service_catalogue app/` — if it is still used for ownership (catalogue-based `owned_by?`), defer removal to Slice F.

### Links polymorphism cleanup

Slice A (A1) deleted the `Link::UseCasesUrl`, `Link::MultimediaUrl`, `Link::ResearchProductLicenseUrl`, `Link::ResearchProductMetadataLicenseUrl` classes. Delete their rows here (polymorphic `linkable_type = 'Service'` only; Provider rows handled in Slice B):

```ruby
execute <<~SQL
  DELETE FROM links
  WHERE linkable_type = 'Service'
    AND type IN (
      'Link::UseCasesUrl',
      'Link::MultimediaUrl',
      'Link::ResearchProductLicenseUrl',
      'Link::ResearchProductMetadataLicenseUrl'
    );
SQL
```

### Full migration skeleton

```ruby
class StripServiceToV6 < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  REMOVED_COLUMNS = %i[
    tagline
    geographical_availabilities
    language_availability
    resource_geographic_locations
    dedicated_for
    helpdesk_url
    manual_url
    training_information_url
    status_monitoring_url
    maintenance_url
    resource_level_url
    helpdesk_email
    security_contact_email
    payment_model_url
    pricing_url
    certifications
    standards
    open_source_technologies
    changelog
    grant_project_names
    related_platforms
    version
    last_update
    restrictions
    activate_message
    horizontal
    abbreviation
    availability_cache
    reliability_cache
    provider_id
  ].freeze

  REMOVED_VOCAB_TYPES = %w[
    Vocabulary::AccessMode
    Vocabulary::FundingBody
    Vocabulary::FundingProgram
    Vocabulary::LifeCycleStatus
    Vocabulary::MarketplaceLocation
    Vocabulary::ServiceCategory
    Vocabulary::EntityType
    Vocabulary::ResearchProductAccessPolicy
    Vocabulary::ResearchProductMetadataAccessPolicy
  ].freeze

  REMOVED_LINK_TYPES = %w[
    Link::UseCasesUrl
    Link::MultimediaUrl
    Link::ResearchProductLicenseUrl
    Link::ResearchProductMetadataLicenseUrl
  ].freeze

  def up
    add_column :services, :publishing_date, :date
    add_column :services, :resource_type, :string
    add_column :services, :urls, :string, array: true, default: []

    execute(
      "DELETE FROM service_vocabularies WHERE vocabulary_type IN (#{REMOVED_VOCAB_TYPES.map { |v| "'#{v}'" }.join(",")})"
    )
    execute(
      "DELETE FROM links WHERE linkable_type = 'Service' AND type IN (#{REMOVED_LINK_TYPES.map { |v| "'#{v}'" }.join(",")})"
    )

    drop_table :service_target_users, if_exists: true
    drop_table :service_related_platforms, if_exists: true
    drop_table :service_relationships, if_exists: true

    REMOVED_COLUMNS.each { |c| remove_column :services, c, if_exists: true }
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
```

### Validate

```bash
rails db:migrate
grep -A 100 'create_table "services"' db/schema.rb | \
  grep -cE "\b(tagline|geographical_availabilities|language_availability|resource_geographic_locations|helpdesk_url|manual_url|training_information_url|status_monitoring_url|maintenance_url|resource_level_url|helpdesk_email|security_contact_email|payment_model_url|pricing_url|certifications|standards|open_source_technologies|changelog|grant_project_names|related_platforms|abbreviation|horizontal|availability_cache|reliability_cache|provider_id)\b"
# Should return 0
grep -cE "\b(publishing_date|resource_type|urls|public_contact_emails)\b" db/schema.rb
# Should return 4 (one per column in services)
```

---

## C3. Update Service model (1.5h)

**File:** `app/models/service.rb`

### Remove (lines to delete exactly)

- `has_many :service_related_platforms, ...` and `has_many :platforms, through: :service_related_platforms`
- `has_many :link_use_cases_urls, ...` and `has_many :link_multimedia_urls, ...`
- `has_many :service_categories, ...` (vocabulary source)
- `has_many :marketplace_locations, ...`
- `has_many :funding_bodies, ...`, `has_many :funding_programs, ...`
- `has_many :access_modes, ...`
- `has_many :life_cycle_statuses, ...`
- `has_many :service_target_users, ...` and `has_many :target_users, through: ...` (per D8 — `TargetUser` model survives for TrainingResource but the Service join is dropped)
- `has_one :main_contact, ...` and `has_many :public_contacts, ...`
- `has_many :source_relationships, ...` and `has_many :target_relationships, ...`
- `has_many :related_services, ...`, `:manual_related_services`, `:required_services`
- `accepts_nested_attributes_for :main_contact`
- `accepts_nested_attributes_for :public_contacts`
- `accepts_nested_attributes_for :link_multimedia_urls`
- `accepts_nested_attributes_for :link_use_cases_urls`
- `serialize :geographical_availabilities, coder: Country::Array`
- `serialize :resource_geographic_locations, coder: Country::Array`
- `scope :horizontal, -> { where(horizontal: true) }`
- All `auto_strip_attributes` entries for: `tagline`, `resource_level_url`, `manual_url`, `helpdesk_url`, `training_information_url`, `restrictions`, `activate_message`, `helpdesk_email`, `status_monitoring_url`, `maintenance_url`, `payment_model_url`, `pricing_url`, `security_contact_email`, `language_availability`, `certifications`, `standards`, `open_source_technologies`, `changelog`, `related_platforms`, `grant_project_names`
- All `validates` entries for those same removed attributes plus `validates :tagline`, `validates :geographical_availabilities`, `validates :language_availability`, `validates :life_cycle_statuses, length: { maximum: 1 }`
- `validates :public_contacts, presence: ...`
- `def aod?` (reads `platforms`)
- `def geographical_availabilities_link` (reads removed column)
- `def languages` (reads removed column)
- `def sliced_tag_list` only if caller list empty (quick `git grep sliced_tag_list` — if only `show.html.haml` uses it, it survives; otherwise inline)

### Keep unchanged

- `include Service::Search`, `include Publishable`, `include Propagable`, `include Viewable`, `include Statusable`, `include OrderableResource`, `include LogoAttachable`
- `acts_as_taggable` (D6)
- `extend FriendlyId; friendly_id :name, use: :slugged`
- `has_many :offers, ...`, `has_many :bundles, ...`, `has_many :project_items, ...`
- `has_many :service_scientific_domains, ...` and `has_many :scientific_domains, through: ...`
- `has_many :categorizations, ...` and `has_many :categories, through: ...`
- `has_many :service_providers, ...` and `has_many :providers, through: :service_providers`
- `has_many :service_alternative_identifiers` + `has_many :alternative_identifiers, through:` (D14)
- `has_many :nodes, through: :service_vocabularies, source_type: "Vocabulary::Node"`
- `has_many :access_types, through: :service_vocabularies, source_type: "Vocabulary::AccessType"`
- `has_many :trls, through: :service_vocabularies, source_type: "Vocabulary::Trl"`
- `belongs_to :resource_organisation, class_name: "Provider", optional: false`
- `belongs_to :jurisdiction, class_name: "Vocabulary::Jurisdiction", optional: true` — now applies to all Services (used to be Datasource-only)
- `has_many :sources, ...` (ServiceSource for upstream tracking)
- `has_many :service_guidelines` / `has_many :guidelines, through:` (Slice H updates)
- `accepts_nested_attributes_for :alternative_identifiers, reject_if: :all_blank, allow_destroy: true`
- `has_many :user_services, ...` / `has_many :favourite_users, ...`
- `has_many :service_user_relationships, ...` / `has_many :owners, ...`
- `accepts_nested_attributes_for :sources, ...`
- `belongs_to :upstream, ...`
- Service ownership via `def owned_by?(user)` — keep but remove the `catalogue.present? && ...` branch if Slice F determines `service_catalogue` is going

### Add

- `validates :publishing_date, presence: true` (only if V6 API guarantees it — confirm in Slice 0 D3 context; if optional in API, omit validation)
- No validation for `urls` or `resource_type` (API may send empty)

### `Presentable` concern cleanup (cross-cutting — same file group)

**File:** `app/models/concerns/presentable.rb`

Remove:

- `def geographical_availabilities=(value)` setter
- `def resource_geographic_locations=(value)` setter
- `def target_relationships` (uses removed `required_services`/`manual_related_services`/`related_services`)

Keep `resource_organisation_and_providers`, `resource_organisation_name`, `external?`, `providers?`, `available_omses` — still used in views and `search_data`.

### Datasource-STI references to leave alone

Slice C leaves `persistent_identity_systems`, `datasource_classification`, `research_entity_types`, `research_product_access_policies`, `research_product_metadata_access_policies`, `link_research_product_license_urls`, `link_research_product_metadata_license_urls` to Slice D — even though Slice A/C2 already deleted the underlying rows. The associations remain declared on the model until Slice D deletes `PersistentIdentitySystem` entirely (per D9; the table is dropped, not reshaped).

### Validate

```bash
grep -nE "has_many :(target_users|access_modes|funding_bodies|funding_programs|life_cycle_statuses|marketplace_locations|service_categories|platforms|service_related_platforms|link_use_cases_urls|link_multimedia_urls|public_contacts|service_target_users|source_relationships|target_relationships|related_services|manual_related_services|required_services)\b" app/models/service.rb
# Should return empty
grep -nE "has_one :main_contact" app/models/service.rb
# Should return empty
grep -nE "validates :(tagline|geographical_availabilities|language_availability|helpdesk_email|security_contact_email|manual_url|helpdesk_url|status_monitoring_url|maintenance_url|payment_model_url|pricing_url|training_information_url|resource_level_url)\b" app/models/service.rb
# Should return empty
bundle exec rails runner 'puts Service.new.valid? ; puts Service.new.errors.full_messages'
# Should not complain about removed attributes
```

---

## C4. Update Service factory (20 min)

**File:** `spec/factories/services.rb`

Remove factory traits and attributes for: `tagline`, `geographical_availabilities`, `language_availability`, `resource_geographic_locations`, `main_contact`, `public_contacts`, `life_cycle_statuses`, `service_categories`, `target_users`, `platforms`, `horizontal`, `abbreviation`, `certifications`, `standards`, `open_source_technologies`, `changelog`, `version`, `last_update`, `related_platforms`, `funding_bodies`, `funding_programs`, `helpdesk_email`, `security_contact_email`, `helpdesk_url`, `manual_url`, `training_information_url`, `status_monitoring_url`, `maintenance_url`, `resource_level_url`, `payment_model_url`, `pricing_url`, `grant_project_names`, `dedicated_for`, `marketplace_locations`.

Add:

```ruby
publishing_date { Date.current }
resource_type { "service" }
public_contact_emails { ["contact@example.org"] }
urls { [] }
```

### Validate

```bash
bundle exec rspec spec/factories_spec.rb spec/models/service_spec.rb
# All green
```

---

## C5. Rewrite `Importers::Service` (45 min)

**File:** `app/services/importers/service.rb`

Complete rewrite (~120 lines → ~55 lines). V6 API fields consumed:

```
id, name, description, webpage, logo, scientificDomains, categories,
accessTypes, tags, trl, termsOfUse, privacyPolicy, accessPolicy, orderType,
order, nodePID, type, publishingDate, publicContacts, resourceOwner,
serviceProviders, jurisdiction, urls, alternativePIDs, status,
mainContact (ignored — D2), users (ignored — D2)
```

```ruby
# frozen_string_literal: true

class Importers::Service < ApplicationService
  include Importable

  def initialize(data, synchronized_at, eosc_registry_base_url, token = nil)
    super()
    @data = data
    @synchronized_at = synchronized_at
    @eosc_registry_base_url = eosc_registry_base_url
    @token = token
  end

  def call
    alt_pids = Array(@data["alternativePIDs"])

    scientific_subdomains = @data["scientificDomains"]&.map { |sd| sd["scientificSubdomain"] } || []
    subcategories = @data["categories"]&.map { |c| c["subcategory"] } || []

    {
      # Identity
      pid: @data["id"],
      ppid: fetch_ppid_from_alt_pids(alt_pids),
      alternative_identifiers: alt_pids.map { |p| map_alt_pid(p) }.compact,
      status: @data["status"],
      synchronized_at: @synchronized_at,
      # Basic
      name: @data["name"],
      description: @data["description"],
      webpage_url: @data["webpage"] || "",
      logo_url: @data["logo"], # consumed by Importers::Logo downstream
      publishing_date: @data["publishingDate"], # ISO 8601 -> Date cast
      resource_type: @data["type"],
      urls: Array(@data["urls"]),
      # Ownership & providers
      resource_organisation: map_provider(@data["resourceOwner"]),
      providers: Array(@data["serviceProviders"]).uniq.map { |p| map_provider(p) }.compact,
      # Nodes — D16
      nodes: map_nodes(Array(@data["nodePID"])),
      # Classification
      scientific_domains: map_scientific_domains(scientific_subdomains),
      categories: map_categories(subcategories) || [],
      tag_list: Array(@data["tags"]),
      access_types: map_access_types(Array(@data["accessTypes"])), # D13 — API is inconsistent: Service returns array, Datasource returns string; Array() handles both
      trls: map_trl(@data["trl"]),
      jurisdiction: map_jurisdiction(@data["jurisdiction"]),
      # Contact — D17
      public_contact_emails: extract_public_contact_emails(@data["publicContacts"]),
      # Legal
      terms_of_use_url: @data["termsOfUse"] || "",
      privacy_policy_url: @data["privacyPolicy"] || "",
      access_policies_url: @data["accessPolicy"] || "",
      # Order
      order_type: map_order_type(@data["orderType"]),
      order_url: @data["order"] || ""
    }
  end

  private

  def map_alt_pid(hash)
    return nil unless hash.is_a?(Hash)
    AlternativeIdentifier.new(identifier_type: hash["pidSchema"], value: hash["pid"])
  end
end
```

### Notes

- `logo_url` is a transient key the orchestrator (`lib/import/resources.rb`) reads out before calling `Service::Create`/`Update` — mirror how Slice B handles `logo_url`.
- `map_jurisdiction` must exist in `Importable` after Slice A (it already does — `ACCEPTED_VOCABULARIES` keeps `JURISDICTION`).
- `map_categories` is UNCHANGED — V6 still uses nested `{category, subcategory}` structure.
- `extract_public_contact_emails` and `fetch_ppid_from_alt_pids` live in `Importable` (added in Slice B5).
- `accessTypes` in V6 is inconsistent (D13): Service returns an array (`["access_type-physical", "access_type-remote"]`), Datasource returns a singular string. `Array()` wrap handles both cases. One-line comment in code is enough — do not change the column type.
- `serviceProviders` may legitimately be empty; V5's `resourceProviders` was often `[resourceOrganisation]` self-reference. V6 keeps this pattern but leave deduplication to downstream `providers.uniq`.
- Do NOT read `mainContact`, `users`, `catalogueId`, `horizontalService`, `tagline`, or any removed V5 field. Silent drop per D2 default (ignore in new importers).

### Validate

```bash
grep -cE "(multimedia|useCases|serviceCategories|horizontalService|targetUsers|accessModes|geographicalAvailabilities|languageAvailabilities|lifeCycleStatus|certifications|standards|openSourceTechnologies|changeLog|requiredResources|relatedResources|relatedPlatforms|fundingBody|fundingPrograms|grantProjectNames|helpdeskPage|userManual|trainingInformation|statusMonitoring|maintenance|serviceLevel|paymentModel|pricing|helpdeskEmail|securityContactEmail|tagline|mainContact|abbreviation)" app/services/importers/service.rb
# Should return 0

grep -cE "(resourceOwner|serviceProviders|nodePID|publishingDate|alternativePIDs|publicContacts|urls)" app/services/importers/service.rb
# Should return 7
```

---

## C6. Rewrite `Import::Resources` orchestrator (30 min)

**File:** `lib/import/resources.rb`

### URL bug (D18)

Current code passes `"service/adminPage"` to `Importers::Request.new`. `Request#all` appends `/all?quantity=10000&from=0`. Change the suffix to:

```ruby
Importers::Request.new(@eosc_registry_base_url, "public/service", faraday: @faraday, token: @token).call
```

Confirm by `curl`ing:

```
https://dev.providers.sandbox.eosc-beyond.eu/api/public/service/all?quantity=10000&from=0
```

### Response shape change

V5 `service/adminPage` returned `{ results: [{ service: {...}, resourceExtras: {...}, metadata: {...}, active, suspended }] }`.
V6 `public/service/all` returns `{ results: [{ ...flat service fields..., type: "service" }] }` with no wrapper. Verify with the curl above before coding.

Rewrite the loop:

```ruby
response.body["results"]
  .select { |res| @ids.empty? || @ids.include?(res["id"]) }
  .each do |service_data|
    output.append(service_data)

    synchronized_at = service_data.dig("metadata", "modifiedAt")&.to_i || Time.now.to_i
    image_url = service_data["logo"]
    service = Importers::Service.call(service_data, synchronized_at, @eosc_registry_base_url, @token)
    service.delete(:logo_url)

    # V6: no active/suspended — public endpoint returns only published
    service[:status] ||= :published
    # ... existing create/update flow continues ...
  end
```

### Remove

- `service_data["resourceExtras"]` merge (no `resourceExtras` in V6)
- `object_status(active, suspended)` call — public endpoint omits these fields. Default new records to `:published`. (If V6 still sends `active/suspended` per a later spec bump, restore.)

### Keep

- `ServiceSource` upstream tracking
- `Importers::Logo.call(service, image_url)` pattern
- Dry-run/rescue-mode branches

### Validate

```bash
DRY_RUN=true bundle exec rake import:resources 2>&1 | tail -40
# Should show "Adding [NEW] service: X" with real V6 PIDs, no 404s, no NoMethodError on resourceExtras
```

---

## C7. Update Service specs (45 min)

### `spec/services/importers/service_spec.rb`

- New fixture `spec/fixtures/service_v6.json` — copy from `curl` of `public/service/all`, pick one entry.
- Remove expectations for `tagline`, `main_contact`, `public_contacts`, `geographical_availabilities`, `language_availability`, `life_cycle_statuses`, `target_users`, `platforms`, funding fields, etc.
- Add expectations for `publishing_date`, `resource_type`, `urls`, `public_contact_emails`, `alternative_identifiers` (from `alternativePIDs`), `nodes`, `jurisdiction`.

### `spec/models/service_spec.rb`

- Remove tests referencing `main_contact`, `public_contacts`, `target_users`, `platforms`, `geographical_availabilities`, `aod?`, `languages`, `geographical_availabilities_link`.
- Add scope `visible` test (already exists — unchanged).
- Add `publishing_date` validation test only if C3 kept that validation.

### `spec/models/concerns/presentable_spec.rb`

Delete tests for removed setters (`geographical_availabilities=`, `resource_geographic_locations=`) and `target_relationships`.

### Validate

```bash
bundle exec rspec spec/models/service_spec.rb spec/services/importers/service_spec.rb spec/models/concerns/presentable_spec.rb
```

---

## C8. Rewrite `Ess::ServiceSerializer` (30 min)

**File:** `app/serializers/ess/service_serializer.rb`

Complete rewrite:

```ruby
# frozen_string_literal: true

class Ess::ServiceSerializer < ApplicationSerializer
  attribute :slug, unless: :datasource?

  attributes :id,
             :pid,
             :ppid,
             :name,
             :description,
             :webpage_url,
             :urls,
             :logo,
             :scientific_domains,
             :categories,
             :tag_list,
             :access_types,
             :trls,
             :jurisdiction,
             :terms_of_use_url,
             :privacy_policy_url,
             :access_policies_url,
             :order_type,
             :order_url,
             :resource_organisation,
             :providers,
             :nodes,
             :guidelines,
             :public_contact_emails,
             :publishing_date,
             :resource_type,
             :status,
             :upstream_id,
             :synchronized_at,
             :updated_at,
             :created_at

  attribute :created_at, key: :publication_date
  attribute :project_items_count, key: :usage_counts_downloads
  attribute :usage_counts_views

  # Datasource-only
  attribute :offers_count, unless: :datasource?
  attribute :service_opinion_count, unless: :datasource?
  attribute :rating, unless: :datasource?

  def datasource?
    object.type == "Datasource"
  end
end
```

### Removed attributes

`catalogues`, `eosc_if`, `abbreviation`, `tagline`, `multimedia_urls`, `use_cases_urls`, `horizontal`, `access_modes`, `platforms`, `funding_programs`, `funding_bodies`, `version`, `status_monitoring_url`, `training_information_url`, `maintenance_url`, `manual_url`, `helpdesk_url`, `helpdesk_email`, `pricing_url`, `payment_model_url`, `changelog`, `security_contact_email`, `certifications`, `standards`, `open_source_technologies`, `grant_project_names`, `last_update`, `geographical_availabilities`, `resource_geographic_locations`, `public_contacts`, `life_cycle_statuses`, `target_users`/`dedicated_for`, `marketplace_locations`/`unified_categories`, `languages`/`language_availability`, `restrictions`, `activate_message`, `phase`, `node` (singular alias), `related_platforms`, `resource_level_url`/`sla_url`.

### Renames to audit downstream (ESS consumer) — per D21

`dedicated_for` and `unified_categories` are gone from the Rails model. Slice 0 D21 decides whether the `Ess::ServiceSerializer` also drops them immediately or keeps them as empty stubs for one cycle. Default (D21): keep the serializer emitting `dedicated_for: []` / `unified_categories: []` until the ESS team confirms — then remove in a follow-up PR.

### Validate

```bash
grep -cE "(tagline|multimedia_urls|use_cases|horizontal|access_modes|platforms|funding_programs|funding_bodies|life_cycle_statuses|version|status_monitoring_url|training_information_url|maintenance_url|changelog|certifications|standards|open_source_technologies|grant_project_names|geographical_availabilities|resource_geographic_locations|dedicated_for|unified_categories|marketplace_locations|language_availability|public_contacts\b)" app/serializers/ess/service_serializer.rb
# Should return 0
```

---

## C9. Update Elasticsearch search_data + facets (45 min)

### `app/models/service/search.rb` — full rewrite

```ruby
# frozen_string_literal: true

module Service::Search
  extend ActiveSupport::Concern

  included do
    searchkick word_middle: %i[name description offer_names resource_organisation_name provider_names node_names],
               highlight: %i[name resource_organisation_name provider_names]
  end

  def search_data
    {
      service_id: id,
      name: name,
      sort_name: name&.downcase,
      description: description,
      status: status,
      rating: rating,
      categories: categories.map(&:id),
      scientific_domains: search_scientific_domains_ids,
      resource_organisation_name: resource_organisation.name,
      providers: resource_organisation_and_providers.map(&:id),
      order_type: [order_type] << offers.published.map(&:order_type),
      tags: tag_list.map(&:downcase),
      source: upstream&.source_type,
      offers: offers.ids,
      offer_names: offers.map(&:name),
      provider_names: [resource_organisation.name] << providers.map(&:name),
      node_names: nodes.map(&:name),
      # V6 additions
      jurisdiction: jurisdiction&.eid,
      publishing_date: publishing_date,
      resource_type: resource_type,
      urls: urls
    }
  end

  private

  def search_scientific_domains_ids
    (scientific_domains.map(&:ancestor_ids) + scientific_domains.map(&:id)).flatten.uniq
  end
end
```

Removed from index: `tagline`, `marketplace_locations`, `platforms`, `geographical_availabilities`, `dedicated_for`.

### `app/controllers/api/v1/search/services_controller.rb` — update facets/aggs/constraints

Remove from `aggs:`: `:platforms`, `:dedicated_for`.
Remove param handlers for `params[:target_users]` (lines ~83-88) and `params[:platforms]` (lines ~90-93).
Remove constraint/filter keys: `:platforms`, `:marketplace_locations`, `:target_users`, `:geographical_availabilities`.
Remove the bucket/sort blocks for `target_users` and `platforms` (~lines 300-310).
Remove `target_users:` and `platforms:` from the response hash (~lines 355-356).

Add facet: `:jurisdiction` (maps to `jurisdiction` in index).

Run `git grep -nE "(target_users|dedicated_for|geographical_availabilities|marketplace_locations|platforms)" app/controllers/api/v1/search/services_controller.rb` — should return empty after edits.

### Post-migration

```bash
rake searchkick:reindex:all
```

(Slice J reminds the deployer to run this; C9 just makes it work.)

### Validate

```bash
grep -cE "(tagline|marketplace_locations|platforms|geographical_availabilities|dedicated_for|language_availability)" app/models/service/search.rb
# Should return 0
grep -cE "(jurisdiction|publishing_date|resource_type|urls)" app/models/service/search.rb
# Should return 4+
bundle exec rspec spec/models/service_search_spec.rb spec/controllers/api/v1/search/services_controller_spec.rb 2>/dev/null || echo "run whichever search specs exist"
```

---

## C10. Update backoffice service form partials (1h)

**Directory:** `app/views/backoffice/services/form/` and `app/views/backoffice/services/` (helper in `app/helpers/backoffice/services_helper.rb` if present).

### Delete partials (removed sections)

- `_availability.html.haml`
- `_management.html.haml` (helpdesk, manual, training, status_monitoring, maintenance, service_level)
- `_financial.html.haml` / `_attribution.html.haml` (payment_model, pricing, funding_bodies, funding_programs, grant_project_names)
- `_maturity.html.haml` (life_cycle, certifications, standards, open_source, version, last_update, changelog)
- `_dependencies.html.haml` (related_services, required_services, related_platforms)
- `_contact.html.haml` (main_contact + public_contacts nested fields)
- `_multimedia.html.haml`, `_use_cases.html.haml` (Link fields)
- `_marketplace_locations.html.haml`, `_service_categories.html.haml`, `_horizontal.html.haml`, `_target_users.html.haml`, `_access_modes.html.haml` if they exist as separate partials

### Keep/update

- `_basic.html.haml` — remove `abbreviation`, `tagline`. Add `urls[]` input (repeater like tags) and `publishing_date` date picker.
- `_classification.html.haml` — keep `scientific_domains`, `categories`, `tags`, `access_type`. Add `jurisdiction` select. Remove `target_users`, `marketplace_locations`, `service_categories`, `horizontal`, `access_modes`.
- `_legal.html.haml` — keep `terms_of_use_url`, `privacy_policy_url`, `access_policies_url`.
- `_order.html.haml` — keep `order_type`, `order_url`.
- `_public_contact_emails.html.haml` — **new** partial, simple email array:

  ```haml
  .form-group
    = f.label :public_contact_emails, "Public contact emails"
    = f.text_area :public_contact_emails_as_text, value: (form.object.public_contact_emails || []).join("\n"), rows: 4, placeholder: "one email per line"
  
    %small.form-text Enter one email address per line.
  ```

  Add controller glue: parse `public_contact_emails_as_text` param in `services_controller.rb` `update`/`create`:

  ```ruby
  if params.dig(:service, :public_contact_emails_as_text)
    emails = params[:service][:public_contact_emails_as_text].to_s.split(/\r?\n/).map(&:strip).reject(&:empty?)
    params[:service][:public_contact_emails] = emails
  end
  ```

- `_organisation.html.haml` (new or renamed) — `resource_organisation_id` (still labeled "Resource owner" in UI).

### Remove controller references to deleted partials

In the parent form/wizard (`app/views/backoffice/services/_form.html.haml` or similar), delete `= render "form/management"`, etc.

### Validate

```bash
grep -rlE "(tagline|geographical_availabilities|language_availability|helpdesk_url|manual_url|payment_model|pricing_url|funding_bod|platform_ids|target_user_ids|life_cycle_statuses|main_contact_attributes)" app/views/backoffice/services/
# Should return empty
```

---

## C11. Update service policy (20 min)

**File:** `app/policies/backoffice/service_policy.rb`

### Remove from `permitted_attributes`

```
:abbreviation, :tagline,
[geographical_availabilities: []], [language_availability: []],
[resource_geographic_locations: []], [target_user_ids: []],
[link_multimedia_urls_attributes: ...], [link_use_cases_urls_attributes: ...],
:resource_level_url, :manual_url, :helpdesk_url, :helpdesk_email,
:security_contact_email, :training_information_url, :status_monitoring_url,
:maintenance_url, :payment_model_url, :pricing_url, :restrictions,
[funding_body_ids: []], [funding_program_ids: []],
[access_mode_ids: []], [certifications: []], [standards: []],
[grant_project_names: []], [open_source_technologies: []], [changelog: []],
:activate_message, :version, :horizontal,
[related_platforms: []], [platform_ids: []],
[service_category_ids: []], [related_service_ids: []],
[required_service_ids: []], [manual_related_service_ids: []],
[life_cycle_status_ids: []], [marketplace_location_ids: []],
[research_entity_type_ids: []], [research_product_access_policy_ids: []],
[research_product_metadata_access_policy_ids: []], [entity_type_scheme_ids: []],
[link_research_product_license_urls_attributes: ...],
[link_research_product_metadata_license_urls_attributes: ...],
[main_contact_attributes: ...], [public_contacts_attributes: ...]
```

Also remove from `MP_INTERNAL_FIELDS`: `:restrictions`, `:activate_message`, `:horizontal`, `[marketplace_location_ids: []]`.

### Add

```
:publishing_date,
:resource_type,
[urls: []],
:jurisdiction_id,
[public_contact_emails: []]
```

### Keep (unchanged)

```
:type, :name, :description, :order_type, :node_ids, [provider_ids: []],
:terms_of_use_url, :access_policies_url, :webpage_url, :privacy_policy_url,
:order_url, [access_type_ids: []], :logo, [trl_ids: []],
[scientific_domain_ids: []], :tag_list, [category_ids: []], [pc_category_ids: []],
:catalogue, :catalogue_id, [owner_ids: []], :status, :upstream_id,
:resource_organisation_id,
# Datasource-owned — unchanged in Slice C, Slice D rewrites
:submission_policy_url, :preservation_policy_url, :version_control,
:jurisdiction_id, :datasource_classification_id, :thematic, :harvestable,
[persistent_identity_systems_attributes: ...],
[sources_attributes: %i[id source_type eid _destroy]],
[alternative_identifiers_attributes: %i[id identifier_type value _destroy]]
```

### Validate

```bash
grep -cE "(tagline|geographical_availabilities|language_availability|target_user_ids|main_contact_attributes|public_contacts_attributes|funding_body_ids|funding_program_ids|access_mode_ids|platform_ids|life_cycle_status_ids|marketplace_location_ids|service_category_ids|related_service_ids|required_service_ids|link_multimedia_urls_attributes|link_use_cases_urls_attributes)" app/policies/backoffice/service_policy.rb
# Should return 0
grep -cE "(publishing_date|resource_type|public_contact_emails|urls)" app/policies/backoffice/service_policy.rb
# Should return 4
```

---

## C12. Update public service views + search filters (1.5h)

### `app/views/services/show.html.haml` and partials

Remove blocks and helpers that reference: `tagline`, `@service.languages`, `@service.geographical_availabilities`, `@service.resource_geographic_locations`, `@service.life_cycle_statuses`, `@service.certifications`, `@service.standards`, `@service.open_source_technologies`, `@service.changelog`, `@service.version`, `@service.last_update`, `@service.helpdesk_url`, `@service.helpdesk_email`, `@service.manual_url`, `@service.training_information_url`, `@service.status_monitoring_url`, `@service.maintenance_url`, `@service.resource_level_url`, `@service.payment_model_url`, `@service.pricing_url`, `@service.security_contact_email`, `@service.funding_bodies`, `@service.funding_programs`, `@service.grant_project_names`, `@service.required_services`, `@service.related_services`, `@service.manual_related_services`, `@service.platforms`, `@service.related_platforms`, `@service.target_users`, `@service.marketplace_locations`, `@service.main_contact`, `@service.public_contacts`, `@service.abbreviation`, `@service.horizontal`, `@service.aod?`, `@service.geographical_availabilities_link`.

Add a simple email list for `@service.public_contact_emails` (just `ul > li > a mailto:`).
Add `publishing_date`, `urls` (list of links), `jurisdiction&.label_or_eid` where sensible.

### `app/views/services/_filters.html.haml` (or wherever frontend facets live)

Remove filter widgets for: `target_users`, `platforms`, `geographical_availabilities`, `funding_bodies`, `funding_programs`, `marketplace_locations`, `life_cycle_statuses`, `access_modes`, `service_categories`.

### `app/views/comparisons/`

Remove comparison rows for the same list. If `comparisons_controller` has a `COMPARABLE_FIELDS` constant, trim it.

### Search params

In `app/controllers/services_controller.rb` (or wherever public service list lives) remove query-param handling for `target_users`, `platforms`, `geographical_availabilities`, etc. Keep `tags`, `categories`, `scientific_domains`, `providers`, `nodes`, `jurisdiction`, `order_type`, `rating`.

### Validate (manual)

```bash
./bin/server
# Browse / (homepage), /services, /services/:slug, /comparisons
# No 500s, no NoMethodError on removed columns in logs.
```

```bash
grep -rlE "(geographical_availabilities|helpdesk_url|payment_model|pricing_url|funding_bod|marketplace_locations|target_users|main_contact|public_contacts[^_]|life_cycle_statuses|tagline|abbreviation)" app/views/services/ app/views/comparisons/
# Should return empty (any stragglers are bugs)
```

---

## C13. Dead-reference sweep (10 min)

After all of C1–C12 land, grep the whole app for the V5 names to catch anything slipped:

```bash
rg -n "(\.tagline|tagline:|\.abbreviation|\.aod\?|\.languages\b|\.geographical_availabilities|\.language_availability|\.resource_geographic_locations|\.life_cycle_statuses|\.target_users|\.platforms\b|\.main_contact|\.public_contacts\b|\.helpdesk_url|\.manual_url|\.helpdesk_email|\.security_contact_email|\.marketplace_locations|\.funding_bodies|\.funding_programs)" app/ spec/ lib/
```

Each remaining hit is either:

- Already legitimately on Datasource-STI (handled in Slice D), or
- A dead reference that WILL crash in production — fix it now.

---

## Validate (full slice)

```bash
# Models + importer
bundle exec rspec spec/models/service_spec.rb \
                  spec/services/importers/service_spec.rb \
                  spec/models/concerns/presentable_spec.rb

# Importer integration
DRY_RUN=true bundle exec rake import:resources 2>&1 | tail -20

# Searchkick index consistency
bundle exec rails runner 'Service.reindex; pp Service.search("*").results.first&.search_data.keys.sort'
# Should NOT include: tagline, marketplace_locations, platforms, geographical_availabilities, dedicated_for, language_availability
# SHOULD include: jurisdiction, publishing_date, resource_type, urls

# Dev server smoke
./bin/server
# Browse public /services, backoffice service edit, comparison
# Monitor log for NoMethodError / undefined method
```

**Commit.** Service is now fully V6.

---

## Out of scope for Slice C (handed to later slices)

- `PersistentIdentitySystem` deletion (per D9 — model + table gone, not reshaped), Datasource-specific fields (`submission_policy_url`, `preservation_policy_url`, `version_control`, `thematic`, `datasource_classification`, `jurisdiction` Datasource-only nuances) — **Slice D**
- New `alternative_pids` column or schema rethink — **not happening** (D14: reuse `alternative_identifiers`)
- `acts_as_taggable` replaced by array column — **not happening** (D6: keep tagging)
- JMS topic rename `service.*` → leave unchanged (Service kept in V6) — handled in **Slice G** only if topics need uplift
- `ServiceRelationship` / `ManualServiceRelationship` / `RequiredServiceRelationship`: model files already deleted in **Slice A1**; table drop — the `service_relationships` table is dropped by Slice A6 (`drop_table ..., if_exists: true`). The explicit `drop_table :service_relationships` in C2 is a belt-and-braces duplicate and is a no-op if A already ran (if_exists guards both migrations); keeping it means C is self-contained if A is reverted. Slice J cleanup only re-greps for orphan references.
- `TargetUser` model deletion — **Slice J** (only if Slice I TrainingResource is cut from scope)
