# Slice B: Provider end-to-end (2d)

Provider fully migrated to V6 Organisation schema: DB, model, factory, importer, serializer, views, policy.

**Depends on Slice 0:** D3 (drop vs archive), D7 (keep LegalStatus vocab), D14 (alternativePIDs reuse alternative_identifiers), D16 (nodePID as EID), D17 (publicContacts defensive parse), D18 (Request URL), D19 (keep DA association, stop importing).

**Depends on Slice A:** `Vocabulary::LegalStatus`, `Vocabulary::HostingLegalEntity`, `Vocabulary::Node` still present; vocab join rows for removed types already cleared.

---

## B1. Data migration — contacts to emails (30 min)

**File:** `db/migrate/XXXXXX_add_public_contact_emails_to_providers.rb`

```ruby
class AddPublicContactEmailsToProviders < ActiveRecord::Migration[7.2]
  def up
    add_column :providers, :public_contact_emails, :string, array: true, default: []

    say_with_time "Backfilling public_contact_emails from public_contacts" do
      Provider.reset_column_information
      Provider.find_each do |p|
        emails = p.public_contacts.pluck(:email).compact.map(&:strip).reject(&:blank?).uniq
        p.update_column(:public_contact_emails, emails)
      end
    end
  end

  def down
    remove_column :providers, :public_contact_emails
  end
end
```

Note: `PublicContact` inherits from `Contact` and has an `email` column (see `app/models/public_contact.rb`, `app/models/contact.rb`). The same model is also used by `Catalogue` — do NOT drop `public_contacts` rows here; Slice F handles its own migration.

---

## B2. DB migration — strip provider table (30 min)

**File:** `db/migrate/XXXXXX_strip_provider_to_v6.rb`

Per D3 default: drop, do not archive. (If operator sets `ARCHIVE=true`, the pre-migration archive task in the deploy runbook captures state first — not part of this migration.)

### Columns to REMOVE

```
street_name_and_number
postal_code
city
region
tagline
certifications               # string array
hosting_legal_entity_string  # legacy string, superseded by hosting_legal_entities vocab (D7)
participating_countries      # string array
affiliations                 # string array
national_roadmaps            # string array
```

### Columns to KEEP (existing)

```
id, name, pid, abbreviation, website, country,
legal_entity, description, status,
upstream_id, synchronized_at, ppid,
created_at, updated_at, usage_counts_views
```

### Columns to ADD

```
public_contact_emails string[] default []   # added in B1
```

Note: `alternativePIDs` (V6) is handled via the existing `alternative_identifiers` join table per D14. No column added here.

### Join rows and auxiliary data to clean up

```ruby
# Taggings for Provider (tags removed from V6 Organisation per D6 default)
execute "DELETE FROM taggings WHERE taggable_type = 'Provider'"

# Provider scientific_domains join (not in V6 Organisation)
execute "DELETE FROM provider_scientific_domains"

# MainContact for Provider (V6 uses publicContacts only)
execute "DELETE FROM contacts WHERE contactable_type = 'Provider' AND type = 'MainContact'"

# PublicContact structured rows for Provider — safe to delete AFTER B1 ran
execute "DELETE FROM contacts WHERE contactable_type = 'Provider' AND type = 'PublicContact'"
```

(`MainContact` and `PublicContact` classes themselves stay — Catalogue still uses them until Slice F.)

### Full migration skeleton

```ruby
class StripProviderToV6 < ActiveRecord::Migration[7.2]
  def up
    execute "DELETE FROM taggings WHERE taggable_type = 'Provider'"
    execute "DELETE FROM provider_scientific_domains"
    execute "DELETE FROM contacts WHERE contactable_type = 'Provider' AND type IN ('MainContact','PublicContact')"

    remove_column :providers, :street_name_and_number
    remove_column :providers, :postal_code
    remove_column :providers, :city
    remove_column :providers, :region
    remove_column :providers, :tagline
    remove_column :providers, :certifications
    remove_column :providers, :hosting_legal_entity_string
    remove_column :providers, :participating_countries
    remove_column :providers, :affiliations
    remove_column :providers, :national_roadmaps
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
```

### Validate

```bash
rails db:migrate
grep -A 30 'create_table "providers"' db/schema.rb | grep -cE "(street_name_and_number|postal_code|city|region|certifications|hosting_legal_entity_string|participating_countries|affiliations|national_roadmaps|tagline)"
# Should return 0
grep "public_contact_emails" db/schema.rb
# Should match at least once
```

---

## B3. Update Provider model (1h)

**File:** `app/models/provider.rb`

### Remove associations (delete these lines)

```ruby
has_many :provider_scientific_domains, dependent: :destroy
has_many :scientific_domains, through: :provider_scientific_domains

has_many :networks, through: :provider_vocabularies, source: :vocabulary, source_type: "Vocabulary::Network"
has_many :structure_types,
         through: :provider_vocabularies,
         source: :vocabulary,
         source_type: "Vocabulary::StructureType"
has_many :esfri_domains, through: :provider_vocabularies, source: :vocabulary, source_type: "Vocabulary::EsfriDomain"
has_many :esfri_types, through: :provider_vocabularies, source: :vocabulary, source_type: "Vocabulary::EsfriType"
has_many :meril_scientific_domains,
         through: :provider_vocabularies,
         source: :vocabulary,
         source_type: "Vocabulary::MerilScientificDomain"
has_many :areas_of_activity,
         through: :provider_vocabularies,
         source: :vocabulary,
         source_type: "Vocabulary::AreaOfActivity"
has_many :societal_grand_challenges,
         through: :provider_vocabularies,
         source: :vocabulary,
         source_type: "Vocabulary::SocietalGrandChallenge"
has_many :provider_life_cycle_statuses,
         through: :provider_vocabularies,
         source: :vocabulary,
         source_type: "Vocabulary::ProviderLifeCycleStatus"

has_one :main_contact, as: :contactable, dependent: :destroy, autosave: true
has_many :public_contacts, as: :contactable, dependent: :destroy, autosave: true
```

### Keep associations

```ruby
has_many :provider_vocabularies, dependent: :destroy # still needed for nodes / legal_statuses / hosting_legal_entities
has_many :nodes, through: :provider_vocabularies, source: :vocabulary, source_type: "Vocabulary::Node"
has_many :legal_statuses, through: :provider_vocabularies, source: :vocabulary, source_type: "Vocabulary::LegalStatus"
has_many :hosting_legal_entities,
         through: :provider_vocabularies,
         source: :vocabulary,
         source_type: "Vocabulary::HostingLegalEntity"

has_many :provider_data_administrators
has_many :data_administrators, through: :provider_data_administrators, dependent: :destroy, autosave: true # per D19
has_many :link_multimedia_urls, as: :linkable, dependent: :destroy, autosave: true, class_name: "Link::MultimediaUrl"
has_many :provider_alternative_identifiers
has_many :alternative_identifiers, through: :provider_alternative_identifiers # per D14
has_many :service_providers, dependent: :destroy
has_many :services, through: :service_providers
has_many :bundles, foreign_key: "resource_organisation_id"
has_many :oms_providers, dependent: :destroy
has_many :omses, through: :oms_providers
has_many :sources, class_name: "ProviderSource", dependent: :destroy
```

### Remove `accepts_nested_attributes_for` entries

```ruby
accepts_nested_attributes_for :main_contact, allow_destroy: true
accepts_nested_attributes_for :public_contacts, allow_destroy: true
```

Keep the rest (`link_multimedia_urls`, `alternative_identifiers`, `sources`, `data_administrators`).

### Remove `acts_as_taggable`

Delete the `acts_as_taggable` line (line 18). Tags are not in V6 Organisation per D6.

### Remove `auto_strip_attributes` entries

```ruby
auto_strip_attributes :street_name_and_number, nullify: false
auto_strip_attributes :postal_code, nullify: false
auto_strip_attributes :city, nullify: false
auto_strip_attributes :region, nullify: false
auto_strip_attributes :hosting_legal_entity_string, nullify: false
auto_strip_attributes :certifications, nullify_array: false
auto_strip_attributes :affiliations, nullify_array: false
auto_strip_attributes :national_roadmaps, nullify_array: false
auto_strip_attributes :tag_list, nullify_array: false
```

Keep the others (`name`, `pid`, `abbreviation`, `website`, `description`, `status`).

### Remove validations

```ruby
# location step
validates :street_name_and_number, presence: true
validates :postal_code, presence: true
validates :city, presence: true
# contacts step
validates :main_contact, presence: true
validates :public_contacts, presence: true, length: { minimum: 1, ... }
# maturity
validates :provider_life_cycle_statuses, length: { maximum: 1 }
```

### Remove the `validate_array_values_uniqueness` method entirely

It references `tag_list`, `certifications`, and `national_roadmaps` — all gone. Also remove the `validate :validate_array_values_uniqueness` line.

### Simplify `remove_empty_array_fields`

The `public_contacts` block is gone. Only the `data_administrators` block remains:

```ruby
def remove_empty_array_fields
  send(
    :data_administrators=,
    data_administrators.reject do |administrator|
      administrator.attributes["created_at"].blank? && administrator.attributes.all? { |_, value| value.blank? }
    end
  )
end
```

### Remove accessor methods

Delete: `def esfri_type=`, `def esfri_type`, `def provider_life_cycle_status=`, `def provider_life_cycle_status`, `def participating_countries=`, `def postal_code_and_city`, `def address`.

Keep: `def legal_status=` / `def legal_status`, `def hosting_legal_entity=` / `def hosting_legal_entity`, `def country=`.

### Remove `serialize :participating_countries, coder: Country::Array`

### Add validations

```ruby
with_options if: -> { required_for_step?("location") } do
  validates :country, presence: true
end

with_options if: -> { required_for_step?("contacts") } do
  validates :public_contact_emails,
            presence: true,
            length: {
              minimum: 1,
              message: "are required. Please add at least one"
            }
  validate :public_contact_emails_format
end

def public_contact_emails_format
  Array(public_contact_emails).each do |e|
    errors.add(:public_contact_emails, "#{e} is not a valid email") unless e =~ URI::MailTo::EMAIL_REGEXP
  end
end
```

### Update `search_data`

```ruby
def search_data
  { provider_id: id, provider_name: name, service_ids: service_ids, node_names: nodes.map(&:name) }
end
```

Already fine — `scientific_domains`/`tags` were not indexed. No change needed.

### Wizard steps update

Per D6/D7/D19, the `extended_form` mode is dead weight — V6 has nothing to put in classification/maturity/dependencies/other. Remove `EXTENDED_STEPS` and the `extended_form` code path entirely. See B9 for form/helper updates.

---

## B4. Update Provider factory (15 min)

**File:** `spec/factories/providers.rb`

### Remove attributes

`street_name_and_number`, `postal_code`, `city`, `region`, `main_contact`, `public_contacts`, `certifications`, `participating_countries`, `affiliations`, `national_roadmaps`, `tagline`, `tag_list`, any vocab associations for removed types (networks, structure_types, esfri_domains, etc.).

Keep `data_administrators` factory (D19).

### Add

```ruby
public_contact_emails { ["contact@example.org"] }
```

### Validate checkpoint 1

```bash
bundle exec rspec spec/models/provider_spec.rb
# Fix failures — this is your fast feedback loop
```

---

## B5. Rewrite `Importers::Provider` (30 min)

**File:** `app/services/importers/provider.rb` (rewrite, ~80 → ~35 lines)

### V6 API response (fields we consume)

Live shape from `GET /public/organisation/all` (integration, 20 orgs). Union of top-level keys across all results:

| Field                | Type / shape observed                                    | Notes                                                                                      |
| -------------------- | -------------------------------------------------------- | ------------------------------------------------------------------------------------------ |
| `id`                 | string (e.g. `"21.11170/cI5H3q"`)                        | Used as `pid`.                                                                             |
| `name`               | string                                                   | —                                                                                          |
| `abbreviation`       | string                                                   | —                                                                                          |
| `website`            | string (URL)                                             | —                                                                                          |
| `country`            | string (ISO alpha-2, e.g. `"NL"`)                        | —                                                                                          |
| `legalEntity`        | boolean                                                  | —                                                                                          |
| `legalStatus`        | string \| `null`                                         | Single value, e.g. `"provider_legal_status-foundation"`. Wrap in `Array`.                  |
| `hostingLegalEntity` | string \| `null`                                         | Single value. Wrap in `Array`. Lookup via `Vocabulary::HostingLegalEntity.eid`.            |
| `description`        | string                                                   | —                                                                                          |
| `logo`               | string (URL)                                             | —                                                                                          |
| `multimedia`         | `[{"multimediaURL": ..., "multimediaName": ...}]`        | —                                                                                          |
| `nodePID`            | string (e.g. `"node-egi"`)                               | Single value per D16. Wrap in `Array`.                                                     |
| `publicContacts`     | `[email, ...]` plain email strings                       | Per D17 keep defensive parse (handle object form if it drifts).                            |
| `alternativePIDs`    | `[{"pid": ..., "pidSchema": ...}]` \| `null` \| _absent_ | Key may be absent, `null`, or an array. `Array(...)` handles all three via the D14 helper. |
| `mainContact`        | `{email, firstName, lastName}`                           | Transitional — ignored per D2.                                                             |
| `users`              | `[{id, email, name, surname}, ...]`                      | Transitional — ignored per D19.                                                            |

Fields **NOT** present (contrast with V5 bundle): `active`, `suspended`, `catalogueId`, `scientificDomains`, `structureTypes`, `certifications`, `participatingCountries`, `affiliations`, `networks`, `esfri*`, `meril*`, `areasOfActivity`, `societalGrandChallenges`, `nationalRoadmaps`, `lifeCycleStatus`, `tagline`, `tags`, `streetNameAndNumber`, `postalCode`, `city`, `region`, `hostingLegalEntity` (string form).

### Full rewrite

```ruby
class Importers::Provider < ApplicationService
  include Importable

  def initialize(data, synchronized_at)
    super()
    @data = data
    @synchronized_at = synchronized_at
  end

  def call
    alt_pids = Array(@data["alternativePIDs"])
    multimedia = Array(@data["multimedia"])

    {
      pid: @data["id"],
      name: @data["name"],
      abbreviation: @data["abbreviation"],
      website: @data["website"],
      country: Country.for(@data["country"])&.alpha2 || "",
      legal_entity: @data["legalEntity"],
      legal_statuses: map_legal_statuses(Array(@data["legalStatus"])),
      hosting_legal_entities: map_hosting_legal_entity(Array(@data["hostingLegalEntity"])),
      description: @data["description"],
      nodes: map_nodes(Array(@data["nodePID"])), # per D16
      link_multimedia_urls: multimedia.map { |m| map_link(m) }.compact,
      public_contact_emails: extract_public_contact_emails(@data["publicContacts"]), # per D17
      alternative_identifiers:
        alt_pids
          .map do |p| # per D14
            AlternativeIdentifier.new(identifier_type: p["pidSchema"], value: p["pid"])
          end
          .compact,
      ppid: fetch_ppid_from_alt_pids(alt_pids),
      synchronized_at: @synchronized_at,
      status: :published
    }
  end

  private

  # V6 shape changed from {type:"EOSC PID", value:"..."} to {pid:"...", pidSchema:"..."}
  def fetch_ppid_from_alt_pids(alt_pids)
    hit = alt_pids.find { |p| p["pidSchema"].to_s.casecmp("eosc pid").zero? }
    hit ? hit["pid"].to_s : ""
  end
end
```

(The legacy `fetch_ppid` in `Importable` stays for now — Slices C/E will update to `fetch_ppid_from_alt_pids` once consolidated. For this slice, keep this Provider-local helper.)

Do NOT import `data_administrators` — `users` field is ignored per D19. Existing DA rows stay; new ones are added via the backoffice.

---

## B6. Update `Import::Providers` orchestrator (15 min)

**File:** `lib/import/providers.rb`

Per D18, pass the suffix WITHOUT the trailing `/all` — `Importers::Request#all` appends `/all?quantity=10000&from=0` itself. Change:

```ruby
# BEFORE
rp = Importers::Request.new(@eosc_registry_base_url, "public/provider/bundle", faraday: @faraday, token: @token).call

# AFTER
rp = Importers::Request.new(@eosc_registry_base_url, "public/organisation", faraday: @faraday, token: @token).call
```

Also: the V5 `bundle` endpoint returned `results: [{ provider: {...}, active:, suspended: }]`. V6 `public/organisation/all` returns the organisation object at the top level (not nested) and **drops `active`/`suspended` entirely**. Every org is treated as active; the importer in B5 already defaults `status: :published`. Update the iteration accordingly:

```ruby
@request_providers = rp.body["results"].select { |o| @ids.empty? || @ids.include?(o["id"]) }

@request_providers.each do |external_data|
  eid = external_data["id"]
  parsed_provider_data = Importers::Provider.call(external_data, Time.now.to_i)
  # V6 public endpoint omits active/suspended — keep the guard pattern for
  # forward-compat in case a future spec restores them.
  if external_data.key?("active")
    parsed_provider_data[:status] = object_status(external_data["active"], external_data["suspended"])
  end
  # ...
end
```

**Spot-check before coding:** run `curl -s "$API_BASE/public/organisation/all?quantity=20&from=0" | jq '.results[0] | keys'` to confirm the live shape. Expected top-level keys (sorted): `abbreviation`, `country`, `description`, `hostingLegalEntity`, `id`, `legalEntity`, `legalStatus`, `logo`, `mainContact`, `multimedia`, `name`, `nodePID`, `publicContacts`, `users`, `website`. `alternativePIDs` is optional and may be `null`. If a future API change nests the object under `"organisation"`, swap `external_data = raw` for `external_data = raw["organisation"]`.

---

## B7. Update Provider importer spec (30 min)

**Files:**

- `spec/services/importers/provider_spec.rb` — replace the V5 JSON fixture with a V6 organisation fixture (see B5 shape). Expectations match the new attrs hash.
- `spec/models/provider_spec.rb` — remove tests for deleted associations/validations, add tests for `public_contact_emails` presence/format.

### Validate checkpoint 2

```bash
bundle exec rspec spec/services/importers/provider_spec.rb
DRY_RUN=true MP_IMPORT_EOSC_REGISTRY_URL=https://integration.providers.sandbox.eosc-beyond.eu/api bundle exec rake import:providers
# Should complete without errors against PC integration instance (20 orgs)
```

---

## B8. Update `Ess::ProviderSerializer` (15 min)

**File:** `app/serializers/ess/provider_serializer.rb`

### Full rewrite

```ruby
class Ess::ProviderSerializer < ApplicationSerializer
  attributes :id,
             :pid,
             :catalogues,
             :name,
             :abbreviation,
             :legal_entity,
             :description,
             :multimedia_urls,
             :country,
             :public_contact_emails,
             :updated_at

  attribute :created_at, key: :publication_date
  attribute :hosting_legal_entities, key: :hosting_legal_entity
  attribute :legal_statuses, key: :legal_status
  attribute :website, key: :webpage_url
  attribute :pid, key: :slug
  attribute :usage_counts_downloads do
    0
  end
  attribute :usage_counts_views
  attribute :node
end
```

Removed fields: `scientific_domains`, `tag_list`, `structure_types`, `street_name_and_number`, `postal_code`, `city`, `region`, `public_contacts`, `certifications`, `participating_countries`, `networks`, `affiliations`, `esfri_domains`, `meril_scientific_domains`, `areas_of_activity`, `societal_grand_challenges`, `national_roadmaps`, `provider_life_cycle_statuses`, `esfri_types`, `tag_list` method.

---

## B9. Update backoffice provider forms (1h)

**Files:**

- `app/views/backoffice/providers/form/*.html.haml`
- `app/helpers/backoffice/providers_helper.rb`
- `app/controllers/backoffice/providers_controller.rb`

### Delete partials

```
app/views/backoffice/providers/form/_classification.html.haml
app/views/backoffice/providers/form/_dependencies.html.haml
app/views/backoffice/providers/form/_maturity.html.haml
app/views/backoffice/providers/form/_other.html.haml
app/views/backoffice/providers/form/_legal_status.html.haml   # merged into _profile per D7 (simple dropdown)
```

Also delete any matching files under `app/views/backoffice/providers/steps/` (the non-extended form directory).

### Simplify remaining partials

- `_profile.html.haml` — keep: name, abbreviation, website, logo, legal_entity, legal_status (simple dropdown using `Vocabulary::LegalStatus.all`), hosting_legal_entity (dropdown using `Vocabulary::HostingLegalEntity.all`), description.
- `_location.html.haml` — remove street/postal/city/region fields. Keep only country.
- `_contacts.html.haml` — remove `main_contact` block and structured `public_contacts` nested-form. Replace with a simple repeating email input bound to `public_contact_emails` (use `f.fields_for :public_contact_emails` is not applicable — use a plain `text_field_tag` list with JS add/remove, or a single `text_area` split on newline).

  Minimal implementation:

  ```haml
  = f.label :public_contact_emails, "Public contact emails (one per line)"
  = f.text_area :public_contact_emails, rows: 4, value: Array(f.object.public_contact_emails).join("\n")
  ```

  In `Backoffice::ProvidersController` `provider_params`, coerce:

  ```ruby
  if params.dig(:provider, :public_contact_emails).is_a?(String)
    params[:provider][:public_contact_emails] = params[:provider][:public_contact_emails]
      .split(/\r?\n/)
      .map(&:strip)
      .reject(&:blank?)
  end
  ```

- `_managers.html.haml` / `_admins.html.haml` — keep as-is (data_administrators for internal auth per D19). Add a short helper text: "Managers are set locally in the Marketplace; they are no longer synced from the Provider Catalogue."
- `_basic.html.haml` — remove any removed-field references.

### Update helper

**File:** `app/helpers/backoffice/providers_helper.rb`

```ruby
module Backoffice::ProvidersHelper
  BASIC_STEPS = %w[profile location contacts managers summary].freeze
  # EXTENDED_STEPS removed — V6 has no classification/maturity/dependencies/other
  # ...
  def basic_steps = BASIC_STEPS
  # Remove def extended_steps
end
```

Also remove the `extended_form` code path in `BackofficeController` / the providers wizard. Anywhere `extended_form` is read, default to `false` and delete the branches.

---

## B10. Update `Backoffice::ProviderPolicy#permitted_attributes` (15 min)

**File:** `app/policies/backoffice/provider_policy.rb`

### Remove attributes

```
[scientific_domain_ids: []]
:tag_list
[structure_type_ids: []]
[certifications: []]
[participating_countries: []]
[affiliations: []]
[network_ids: []]
[esfri_domain_ids: []]          # listed twice currently; remove both (lines 65-66)
[esfri_type_ids: []]
:esfri_type
[meril_scientific_domain_ids: []]
[area_of_activity_ids: []]
[societal_grand_challenge_ids: []]
[national_roadmaps: []]
:provider_life_cycle_status
[provider_life_cycle_status_ids: []]
:street_name_and_number
:postal_code
:city
:region
:hosting_legal_entity_string
[main_contact_attributes: ...]
[public_contacts_attributes: ...]
```

### Add attribute

```ruby
[public_contact_emails: []]
```

### Keep

`data_administrators_attributes` (D19), `link_multimedia_urls_attributes`, `alternative_identifiers_attributes`, `sources_attributes`, `legal_status`, `[legal_status_ids: []]`, `:hosting_legal_entity`, basic fields.

---

## B11. Update Provider public views (30 min)

**Files:** `app/views/providers/show.html.haml` and any partials under `app/views/providers/`.

### Remove sections/partials

Address block (street/postal/city/region), scientific domains, tags, structure types, certifications, life cycle status, ESFRI info, MERIL, networks, areas of activity, grand challenges, national roadmaps, participating countries, affiliations, main_contact, tagline.

### Replace contacts section

Render `@provider.public_contact_emails` as a simple email list (mailto links). Drop the structured-contact partial.

### Grep for dead references

```bash
grep -rnE "(street_name_and_number|postal_code|city|region|scientific_domains|tagline|structure_types|certifications|provider_life_cycle_status|esfri|meril|networks|areas_of_activity|societal_grand|national_roadmaps|participating_countries|affiliations|main_contact)" app/views/providers/
# Should return empty
```

---

## Validate (full slice)

```bash
bundle exec rspec spec/models/provider_spec.rb spec/services/importers/provider_spec.rb
bundle exec rspec spec/policies/backoffice/provider_policy_spec.rb   # if exists

# Serializer must not have dead fields:
grep -cE "(scientific_domains|tag_list|structure_types|street_name_and_number|postal_code|city|region|certifications|participating_countries|networks|affiliations|esfri_domains|meril_scientific_domains|areas_of_activity|societal_grand_challenges|national_roadmaps|provider_life_cycle_status|esfri_type)" app/serializers/ess/provider_serializer.rb
# Should return 0

# Importer must not have dead fields:
grep -cE "(scientificDomains|structureTypes|certifications|participatingCountries|affiliations|networks|esfriDomains|esfriType|merilScientific|areasOfActivity|societalGrand|nationalRoadmaps|lifeCycleStatus|tagline|mainContact|streetNameAndNumber|postalCode|\"city\"|\"region\")" app/services/importers/provider.rb
# Should return 0

# Integration-instance dry-run:
MP_IMPORT_EOSC_REGISTRY_URL=https://integration.providers.sandbox.eosc-beyond.eu/api DRY_RUN=true bundle exec rake import:providers

# Start dev server, click through provider creation wizard in backoffice
./bin/server
```

**Commit.** Provider is now fully V6.
