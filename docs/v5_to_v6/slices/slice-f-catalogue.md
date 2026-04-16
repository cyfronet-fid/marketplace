# Slice F: Catalogue (0.5d — **DEFERRED per D1 default**)

## Status

**Slice F is deferred to a follow-up PR.** Per Slice 0 decision D1, while the V6 Catalogue schema is unconfirmed, F is cut from scope and this migration ships without Catalogue changes. Current state:

- **Endpoint:** `GET /catalogue/all` (200, unauthenticated) — no `/public/` variant exists for Catalogue. Admin wrapper at `/catalogue/bundle/all` (403).
- **Payload still V5-shaped:** every field earmarked for removal below is still returned; `publicContacts` is array-of-objects; `nodePID` / `alternativePIDs` are absent.
- The V6 eosc-resources-model repo has no `Catalogue*.java` under `src/main/java/.../domain/`.

**Action:** Do NOT edit any Catalogue code in this migration. The existing V5 import path (`lib/import/catalogues.rb` → `Importers::Catalogue`) continues to run against the legacy endpoint until Catalogue V6 lands.

**Dependency note for downstream slices:** Slice B's Provider model removed `main_contact` / `public_contact` structured fields — the `MainContact` and `PublicContact` Rails classes stay alive because Catalogue still uses them (see `app/models/catalogue.rb`). Slice J cleanup does NOT delete those classes until Slice F ships.

---

## What Slice F will look like when it unblocks

This is a concrete spec to execute once Athena publishes the Catalogue V6 schema. Verify each assumption against the real schema before coding.

### F1. DB migration — strip `catalogues` table (~20 min)

**File:** `db/migrate/YYYYMMDDHHMMSS_strip_catalogue_to_v6.rb`

Assumed removals (mirrors Provider/Organisation simplification):

```
inclusion_criteria   (string, default: "")
validation_process   (string, default: "")
end_of_life          (string, default: "")
scope                (text, default: "")
street_name_and_number, postal_code, city, region, country, participating_countries, affiliations
structure_type       (string array)
tags                 (string array) — D6 removes tagging from Catalogue
```

Add (same pattern as Organisation/Service):

```
publishing_date       :date                    (if Catalogue gets a publication date in V6)
public_contact_emails :string, array: true, default: []
```

Data preserved first (same pattern as Slice B/C):

```ruby
Catalogue.unscoped.find_each do |c|
  emails = PublicContact.where(contactable_type: "Catalogue", contactable_id: c.id).pluck(:email).compact.uniq
  c.update_columns(public_contact_emails: emails) unless emails.empty?
end
```

Then drop the polymorphic `PublicContact` / `MainContact` rows for Catalogue:

```ruby
execute "DELETE FROM contacts WHERE contactable_type = 'Catalogue'"
```

Vocabulary join rows (`catalogue_vocabularies`) to delete:

```
Vocabulary::Network                    # D12: REGION/LANGUAGE not added for Catalogue; Network removed
# Keep: Vocabulary::LegalStatus, Vocabulary::HostingLegalEntity, Vocabulary::Node
```

`acts_as_taggable` (D6): delete `taggings` rows for `taggable_type = 'Catalogue'` in the same migration.

Archive (D3): if `ARCHIVE=true`, dump to `tmp/v5_archive_catalogues_YYYYMMDD.json` — merge into the shared `rake db:v5_archive` task introduced in Slice B.

### F2. Update Catalogue model

**File:** `app/models/catalogue.rb`

Remove:

- `acts_as_taggable`
- `serialize :participating_countries, coder: Country::Array`
- `serialize :country, coder: Country`
- `has_many :catalogue_scientific_domains` + `has_many :scientific_domains, through:`
- `has_one :main_contact`, `has_many :public_contacts`
- `has_many :link_multimedia_urls`
- `has_many :networks, through: :catalogue_vocabularies, source_type: "Vocabulary::Network"`
- `participating_countries=`, `country=`, `affiliations=` setters
- Validations: `inclusion_criteria`, `end_of_life`, `validation_process`, `scope`, `street_name_and_number`, `postal_code`, `city`, `country`, `public_contacts`
- `accepts_nested_attributes_for :main_contact`, `:public_contacts`, `:link_multimedia_urls`

Keep (per D19):

- `has_many :catalogue_data_administrators`, `has_many :data_administrators, through:` — for MP auth
- `accepts_nested_attributes_for :data_administrators` — backoffice users still add DAs manually
- DROP `validates :data_administrators, presence: true` — importers no longer populate DAs from `users` field per D19. An empty `data_administrators` is valid now (operator adds them via backoffice).

Add:

- `validates :public_contact_emails, ...` only if V6 API guarantees non-empty (likely not)

### F3. Rewrite `Importers::Catalogue`

**File:** `app/services/importers/catalogue.rb`

Skeleton (V6-shaped, to fill once schema lands):

```ruby
class Importers::Catalogue < ApplicationService
  include Importable

  def initialize(data, synchronized_at)
    super()
    @data = data
    @synchronized_at = synchronized_at
  end

  def call
    alt_pids = Array(@data["alternativePIDs"])

    {
      pid: @data["id"],
      name: @data["name"],
      abbreviation: @data["abbreviation"] || "",
      description: @data["description"] || "",
      website: @data["website"] || "",
      legal_entity: @data["legalEntity"] || false,
      legal_statuses: map_legal_statuses(Array(@data["legalStatus"])),
      hosting_legal_entities: map_hosting_legal_entity(@data["hostingLegalEntity"]),
      nodes: map_nodes(Array(@data["nodePID"])), # D16
      public_contact_emails: extract_public_contact_emails(@data["publicContacts"]), # D17
      alternative_identifiers: alt_pids.map { |p| map_alt_pid(p) }.compact, # D14
      ppid: fetch_ppid_from_alt_pids(alt_pids),
      status: :published,
      synchronized_at: @synchronized_at
    }
  end
end
```

Fields NOT mapped (V6 drops them): `multimedia`, `tags`, `scientificDomains`, `networks`, `location.*`, `participatingCountries`, `affiliations`, `structureType`, `inclusionCriteria`, `validationProcess`, `endOfLife`, `scope`, `mainContact`, `users`.

Per D19: do NOT populate `data_administrators` from `@data["users"]`.

### F4. Orchestrator URL fix (D18)

**File:** `lib/import/catalogues.rb`

Change suffix to `"catalogue"` (no `/all`, no `/bundle`, and — unique to Catalogue — **no `/public/` prefix** because V6 does not expose one for this entity type). Final URL: `catalogue/all?quantity=10000&from=0`. The endpoint is unauthenticated; the V5 token plumbing in `Import::Catalogues#external_catalogues_data` can be dropped at this point, or kept if `/catalogue/bundle/all` becomes the preferred source once V6 wrappers stabilise.

### F5. `Ess::CatalogueSerializer`

Strip `scientific_domains`, `networks`, location fields, `tagline`, `multimedia_urls`, `participating_countries`, `affiliations`, `structure_type`, `inclusion_criteria`, `validation_process`, `end_of_life`, `scope`, `main_contact`, `public_contacts`, `tag_list`.

Add: `public_contact_emails`, `alternative_pids`.

### F6. Views + policies

Backoffice form sections to delete: `_address`, `_contact`, `_multimedia`, `_classification` (scientific domains + networks + tags).
Keep: `_basic` (name, description, website, abbreviation, legal_entity, legal_status, hosting_legal_entity, nodes), `_managers` (data_administrators manual assignment — per D19).

Policy: remove `[scientific_domain_ids: []]`, `[network_ids: []]`, `[participating_countries: []]`, `[affiliations: []]`, `[structure_type: []]`, `[link_multimedia_urls_attributes: ...]`, `[main_contact_attributes: ...]`, `[public_contacts_attributes: ...]`. Add `[public_contact_emails: []]`, `[alternative_identifiers_attributes: ...]`.

### F7. Validation suite

```bash
bundle exec rspec spec/models/catalogue_spec.rb \
                  spec/services/importers/catalogue_spec.rb \
                  spec/policies/backoffice/catalogue_policy_spec.rb

grep -A 30 'create_table "catalogues"' db/schema.rb | grep -cE "(inclusion_criteria|validation_process|end_of_life|scope|street_name_and_number|participating_countries|affiliations|structure_type)"
# Should return 0

DRY_RUN=true bundle exec rake import:catalogues 2>&1 | tail -10
# "PROCESSED: N, CREATED: ..."  — no 404, no NoMethodError
```

---

## If Slice F unblocks mid-migration

1. Re-curl `/catalogue/all` — if the response body no longer contains V5-only fields (`inclusionCriteria`, `location`, object-form `publicContacts`, `mainContact`, `users`, `scientificDomains`, `tags`) and starts returning `publicContacts` as an email array plus `nodePID`/`alternativePIDs`, copy one record into `spec/fixtures/catalogue_v6.json`.
2. Execute F1–F7 in order.
3. Mark D1 decision resolved in README.md open-questions.
4. Update `docs/v5_to_v6/GUIDE.md` Catalogue section with the confirmed V6 schema.
5. Slice J cleanup can now delete `MainContact`, `PublicContact`, `Contact` classes (no other model references them).

If it does NOT unblock: keep the deferral, ship the migration without Catalogue changes, and file a follow-up issue citing this slice.
