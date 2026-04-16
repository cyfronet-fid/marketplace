# Slice E: DeployableService (0.5d)

V6 renames **Deployable Software → Deployable Application** at the API layer. The Rails model name (`DeployableService`) stays — no class rename in this slice (a rename is a much bigger diff across controllers, routes, views, JMS, policies; defer to Slice J or a follow-up). The import pipeline and schema move to V6 shape.

**Depends on Slice 0 decisions:** D3 (drop removed data), D14 (reuse `alternative_identifiers`), D15 (add `urls` column), D16 (`nodePID` is EID; wrap in `Array()`), D17 (defensive `publicContacts`), D18 (URL bug).

**Depends on Slice A:** `map_nodes`, `map_scientific_domains`, `map_provider`, `extract_public_contact_emails`, `fetch_ppid_from_alt_pids`, `map_alt_pid` helpers already in place in `Importable`.

**V6 payload shape:** live keys on `/public/deployableApplication/all`: `acronym, creators, description, id, lastUpdate, logo, name, nodePID, publicContacts, publishingDate, resourceOwner, scientificDomains, tagline, tags, type, version`. `urls`, `accessTypes`, `alternativePIDs`, and `license` are not populated on any live record — producers omit when empty (per D15 / D14), so the importer uses `Array(...)` / nil-tolerant parses. `type` returns `"DeployableApplication"`.

---

## E1. DB migration — deployable_services table (30 min)

**File:** `db/migrate/YYYYMMDDHHMMSS_update_deployable_services_to_v6.rb`

### Columns to ADD

```
publishing_date       :date
resource_type         :string          # value: "deployable_application"
public_contact_emails :string, array: true, default: []
license_name          :string
license_url           :string
urls                  :string, array: true, default: []    # D15
```

### Columns to DROP

```
software_license  (string)  — replaced by license_name / license_url pair
```

### Columns to KEEP

```
name (null: false), description (null: false), tagline (null: false),
abbreviation, url, node (string), version, last_update, creators (jsonb),
slug, status, pid, upstream_id, synchronized_at, resource_organisation_id,
catalogue_id, created_at, updated_at
```

### `url` vs `urls` decision

V6 adds a top-level `urls` (array of strings) alongside a legacy single `url`. Add the `urls` column; KEEP the existing `url` column untouched. Rationale: every view/partial and `webpage_url` / `order_url` override in `deployable_service.rb:146-151` reads `url` — ripping it out in this 0.5d slice would cascade into form and view work already scoped to Slice C. The importer maps `urls[0]` (if present) into `url` for backwards compat, and also stores the full array in `urls`.

### Full migration

```ruby
class UpdateDeployableServicesToV6 < ActiveRecord::Migration[7.2]
  def up
    add_column :deployable_services, :publishing_date, :date
    add_column :deployable_services, :resource_type, :string
    add_column :deployable_services, :public_contact_emails, :string, array: true, default: []
    add_column :deployable_services, :license_name, :string
    add_column :deployable_services, :license_url, :string
    add_column :deployable_services, :urls, :string, array: true, default: []

    remove_column :deployable_services, :software_license, :string, if_exists: true
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
```

### Note on `alternativePIDs` for DeployableService

V6 adds `alternativePIDs`. `alternative_identifiers` is a polymorphic join with no `deployable_service` branch (grep `app/models/alternative_identifier.rb` — `belongs_to :provider` + `belongs_to :service` through join tables).

**Default:** For Slice E, **skip `alternativePIDs` storage**. Rationale: no live DS-A record carries alt PIDs; the V5 importer doesn't read them; adding a new polymorphic branch is out of this 0.5d budget. Record as a known gap in Slice J's cleanup doc.

If DS-A alt PIDs become mandatory, add:

```ruby
create_join_table :deployable_services,
                  :alternative_identifiers,
                  table_name: :deployable_service_alternative_identifiers
```

plus association + importer mapping. Budget +30 min.

### Validate

```bash
rails db:migrate
grep -A 30 'create_table "deployable_services"' db/schema.rb | grep -cE "\b(publishing_date|resource_type|public_contact_emails|license_name|license_url|urls)\b"
# Should return 6
grep -A 30 'create_table "deployable_services"' db/schema.rb | grep -cE "\bsoftware_license\b"
# Should return 0
```

---

## E2. Update DeployableService model (15 min)

**File:** `app/models/deployable_service.rb`

### Remove

```ruby
auto_strip_attributes :software_license, nullify: false
```

And the stub methods that returned hard-coded V5 values, replacing them with real columns:

- `def tagline` ... `super || ""` — delete (still a stub override, keep the column but remove the safety net since V6 also sends it)
- `def public_contacts; []; end` → delete; replaced by real `public_contact_emails` array
- `def main_contact; nil; end` → keep (V6 no longer sends `mainContact`, UI may still call this — leaving returns nil)

### Add

```ruby
auto_strip_attributes :license_name, nullify: false
auto_strip_attributes :license_url, nullify: false
auto_strip_attributes :resource_type, nullify: false

# No validation on publishing_date or urls — V6 may send nil on both.
```

### Add alias consistent with Service

```ruby
# Per E1 decision, `url` stays. `urls` is the new array. Expose both:
def all_urls
  (Array(urls) + [url]).compact.reject(&:empty?).uniq
end
```

### Keep untouched

- `nodes` stub (`[node_vocabulary].compact`) still works with `node` singular column
- `scientific_domains` association
- `acts_as_taggable`, `has_one_attached :logo`, Publishable, Statusable, Viewable, OrderableResource
- `belongs_to :catalogue` — unchanged

### Validate

```bash
grep -cE "\bsoftware_license\b" app/models/deployable_service.rb
# Should return 0
grep -cE "\b(license_name|license_url|publishing_date|resource_type|public_contact_emails|urls)\b" app/models/deployable_service.rb
# Should return 6+
```

---

## E3. Rewrite `Importers::DeployableService` (20 min)

**File:** `app/services/importers/deployable_service.rb`

V6 field map:

```
id               -> pid
name             -> name
description      -> description
tagline          -> tagline
logo             -> logo_url (consumed by Importers::Logo in orchestrator)
acronym          -> abbreviation            # confirm — V6 may rename to `abbreviation`; keep mapping both
publishingDate   -> publishing_date
type             -> resource_type            # expected: "deployable_application"
resourceOwner    -> resource_organisation (map_provider)
nodePID          -> node (single string; D16)
publicContacts   -> public_contact_emails  (D17 defensive parse)
urls             -> urls (array) + url (first element)  (D15)
version          -> version
lastUpdate       -> last_update (ISO 8601 -> datetime cast)
license          -> license_name + license_url          # V6 sends {name, url}
scientificDomains -> scientific_domains
tags             -> tag_list
creators         -> creators (jsonb — pass through)
```

```ruby
# frozen_string_literal: true

class Importers::DeployableService < ApplicationService
  include Importable

  def initialize(data, synchronized_at, eosc_registry_base_url, token = nil)
    super()
    @data = data
    @synchronized_at = synchronized_at
    @eosc_registry_base_url = eosc_registry_base_url
    @token = token
  end

  def call
    scientific_subdomains = @data["scientificDomains"]&.map { |sd| sd["scientificSubdomain"] } || []
    urls = Array(@data["urls"])
    license = @data["license"].is_a?(Hash) ? @data["license"] : {}

    {
      pid: @data["id"],
      name: @data["name"],
      abbreviation: @data["acronym"] || @data["abbreviation"],
      description: @data["description"],
      tagline: @data["tagline"],
      logo_url: @data["logo"],
      resource_organisation: map_provider(@data["resourceOwner"]),
      node: Array(@data["nodePID"]).first, # D16 — wrap then take first for singular column
      urls: urls,
      url: urls.first, # backwards compat; E1 decision
      public_contact_emails: extract_public_contact_emails(@data["publicContacts"]),
      publishing_date: @data["publishingDate"],
      resource_type: @data["type"],
      version: @data["version"],
      last_update: @data["lastUpdate"],
      license_name: license["name"],
      license_url: license["url"],
      creators: Array(@data["creators"]),
      tag_list: Array(@data["tags"]),
      scientific_domains: map_scientific_domains(scientific_subdomains),
      synchronized_at: @synchronized_at,
      status: :published
    }
  end
end
```

### Removed from importer

- `map_catalogue(@data["catalogueId"])` — V6 does not send `catalogueId` on the public endpoint
- `software_license` → replaced by `license_name` / `license_url`
- Reading `@data["node"]` (V5 name) — now `@data["nodePID"]`
- Reading `@data["resourceOrganisation"]` (V5 name) — now `@data["resourceOwner"]`
- Reading `@data["url"]` (singular V5) — replaced by `urls` array (with fallback to `url` if present)

### Validate

```bash
grep -cE "(softwareLicense|resourceOrganisation|catalogueId|@data\[\"node\"\])" app/services/importers/deployable_service.rb
# Should return 0
grep -cE "(nodePID|resourceOwner|publishingDate|publicContacts|alternativePIDs|urls|license)" app/services/importers/deployable_service.rb
# Should return 6+
```

---

## E4. Rewrite `Import::DeployableServices` orchestrator (15 min)

**File:** `lib/import/deployable_services.rb`

### URL bug (D18)

Current code: `"public/deployableService"` (returns 404 in V6). Change to:

```ruby
Importers::Request.new(@eosc_registry_base_url, "public/deployableApplication", faraday: @faraday, token: @token).call
```

`Request#all` appends `/all?quantity=10000&from=0` → final URL `public/deployableApplication/all?quantity=10000&from=0`.

### Response shape

V6 returns flat records (same pattern as Services/Datasources). The current orchestrator already treats `external_data` as flat — no wrapper to strip. Keep existing `.each do |external_data|` loop structure.

### `object_status` branch

V5 sent `active`/`suspended`. V6 public endpoint likely omits both. The current code only calls `object_status` when `external_data.key?("active")` — leave as defensive guard; default `status: :published` inside the importer (E3) handles the V6 case.

### Logo download path

Changed `external_data["logo"]` is already flat — no change needed.

### Validate

```bash
grep -cE "public/deployableService\b" lib/import/deployable_services.rb
# Should return 0
grep -cE "public/deployableApplication\b" lib/import/deployable_services.rb
# Should return 1

DRY_RUN=true bundle exec rake import:deployable_services 2>&1 | tail -10
# Should log a PROCESSED count with no 404s
```

---

## E5. Update `Ess::DeployableServiceSerializer` (15 min)

**File:** `app/serializers/ess/deployable_service_serializer.rb`

### Remove

`software_license` attribute (if present).

### Add

```
:publishing_date, :resource_type, :public_contact_emails, :license_name,
:license_url, :urls
```

Audit remaining attributes: since ESS treats DeployableService as a Service-like resource, fields like `tagline`, `creators`, `version`, `last_update` stay. Run `git diff` afterwards and hand to ESS team if the schema needs coordination (note in Slice J).

### Validate

```bash
grep -cE "(software_license)" app/serializers/ess/deployable_service_serializer.rb
# Should return 0
```

---

## E6. Specs + fixtures (30 min)

### `spec/services/importers/deployable_service_spec.rb`

New hand-crafted V6 JSON fixture (upstream returns 0 records). Template:

```json
{
  "id": "21.T15999/DA-example",
  "name": "Example DA",
  "description": "An example deployable application",
  "tagline": "Example tagline",
  "acronym": "EXDA",
  "logo": "https://example.org/logo.png",
  "publishingDate": "2026-04-15",
  "type": "deployable_application",
  "resourceOwner": "21.T15999/dAyH3s",
  "nodePID": "node-eosc",
  "publicContacts": ["ops@example.org"],
  "urls": ["https://example.org/app"],
  "version": "1.2.0",
  "lastUpdate": "2026-04-14",
  "license": { "name": "Apache-2.0", "url": "https://www.apache.org/licenses/LICENSE-2.0" },
  "scientificDomains": [{ "scientificDomain": "...", "scientificSubdomain": "..." }],
  "tags": ["alpha"],
  "creators": [{ "name": "Alice", "email": "alice@example.org" }]
}
```

Expectations: `pid`, `abbreviation` from `acronym`, `url` == first of `urls`, `urls == ["..."]`, `license_name == "Apache-2.0"`, `license_url == "..."`, `public_contact_emails == ["ops@example.org"]`, `publishing_date == Date.new(2026,4,15)`, `status == :published`.

### `spec/models/deployable_service_spec.rb`

Delete any test of `software_license`. Add coverage for `license_name`, `license_url`, `urls`.

### Validate

```bash
bundle exec rspec spec/models/deployable_service_spec.rb spec/services/importers/deployable_service_spec.rb
```

---

## E7. Backoffice + public views (10 min — defer deep rewrite)

Deployable Service forms / show pages are lightweight compared to Service. For this slice:

1. `grep -rln "software_license" app/views/` — replace each reference with a two-row block for `license_name` / `license_url`.
2. No new partial work for `publishing_date` / `resource_type` / `urls` / `public_contact_emails` unless backoffice has been asking for them (flag in Slice J if skipped here).

### Validate

```bash
grep -rln "software_license" app/views/
# Should return empty
```

---

## Validate (full slice)

```bash
bundle exec rspec spec/models/deployable_service_spec.rb \
                  spec/services/importers/deployable_service_spec.rb

# Importer check:
grep -cE "(softwareLicense|resourceOrganisation|@data\[\"node\"\])" app/services/importers/deployable_service.rb
# Should return 0

# Endpoint check:
grep -rcE "public/deployableService" lib/import/
# Should return 0
grep -rc "public/deployableApplication" lib/import/
# Should return 1

DRY_RUN=true bundle exec rake import:deployable_services 2>&1 | tail -5
# "PROCESSED: 0" or "PROCESSED: N" — no 404, no NoMethodError
```

**Commit.**

---

## Out of scope for Slice E

- Renaming the Rails class `DeployableService` → `DeployableApplication`. Handled by Slice J cleanup if pursued.
- `alternativePIDs` storage on DS-A (noted E1).
- New facet in public search UI for DS-A.
- URL column consolidation (`url` → `urls[0]` sole source). Requires view-layer sweep; defer to Slice J.
- JMS topic rename `deployable_software.*` → `deployable_application.*`. Handled in Slice G.
