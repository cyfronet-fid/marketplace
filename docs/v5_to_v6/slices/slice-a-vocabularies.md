# Slice A: Vocabularies + Importable cleanup (1d)

**Why first:** Vocabularies are a dependency for everything else. Deleting 18 vocabulary models and their `map_*` methods in Importable is a clean cut with no entity-specific entanglement. Vocabularies have their own import pipeline, so you can validate the full cycle independently.

**Depends on Slice 0:** D7 (keep LegalStatus/HostingLegalEntity), D8 (keep TargetUser), D9 (drop EntityType/EntityTypeScheme/ResearchProductAccessPolicy), D10 (drop SUPERCATEGORY).

---

## A1. Delete vocabulary model files (15 min)

Delete these 18 files from `app/models/vocabulary/`:

```
access_mode.rb
area_of_activity.rb
entity_type.rb
entity_type_scheme.rb
esfri_domain.rb
esfri_type.rb
funding_body.rb
funding_program.rb
life_cycle_status.rb
marketplace_location.rb
meril_scientific_domain.rb
network.rb
provider_life_cycle_status.rb
research_product_access_policy.rb
research_product_metadata_access_policy.rb
service_category.rb
societal_grand_challenge.rb
structure_type.rb
```

Also delete:

- `app/models/platform.rb`
- `app/models/service_relationship.rb`, `app/models/required_service_relationship.rb`, `app/models/manual_service_relationship.rb`
- `app/models/link/use_cases_url.rb`
- `app/models/link/research_product_license_url.rb`
- `app/models/link/research_product_metadata_license_url.rb`

### Vocabulary models to KEEP (9)

- `Vocabulary::Trl`
- `Vocabulary::AccessType`
- `Vocabulary::Jurisdiction`
- `Vocabulary::DatasourceClassification`
- `Vocabulary::Node`
- `Vocabulary::LegalStatus` (per D7)
- `Vocabulary::HostingLegalEntity` (per D7)
- `Vocabulary::BundleGoal` (internal to MP, not from PC)
- `Vocabulary::BundleCapabilityOfGoal` (internal to MP)

### Other models to KEEP

- `app/models/target_user.rb` (per D8 — used by Slice I TrainingResource `targetGroups`)
- `app/models/link/multimedia_url.rb` (still in V6 Provider schema)

---

## A2. Clean Importable concern (30 min)

**File:** `app/models/concerns/importable.rb`

### Remove these 22 `map_*` methods (delete body + signature)

```
map_access_modes
map_access_policies                    # Vocabulary::ResearchProductAccessPolicy removed
map_areas_of_activity
map_data_administrator                 # per D19, no longer imported from PC
map_entity_types
map_esfri_domains
map_esfri_types
map_funding_bodies
map_funding_programs
map_life_cycle_status
map_marketplace_location_ids
map_meril_scientific_domains
map_metadata_access_policies           # Vocabulary::ResearchProductMetadataAccessPolicy removed
map_networks
map_persistent_identity_system         # PID system entirely dropped per D9 — Slice D deletes model + tables
map_platforms
map_provider_life_cycle_status
map_related_services
map_service_categories
map_societal_grand_challenges
map_structure_types
map_target_users                       # Service no longer uses; if TR importer needs it later, add back then
```

### Trim `map_link` (MANDATORY — will crash otherwise)

Current `map_link` in `app/models/concerns/importable.rb:47-68` has four `case` branches: `multimedia`, `use_cases`, `research_product_metadata`, `research_product`. The last three reference classes being deleted in A1. Rewrite the method to keep ONLY the `multimedia` path (with the early-return updated to check only `multimediaURL`):

```ruby
def map_link(link, type = "multimedia")
  return if link&.[]("multimediaURL").blank? && !UrlHelper.url?(link)
  if type == "multimedia"
    Link::MultimediaUrl.new(
      name: link&.[]("multimediaName") || "",
      url: link.is_a?(Hash) ? link["multimediaURL"] : link
    )
  end
end
```

Remove the `# rubocop:disable Metrics/CyclomaticComplexity` / `# rubocop:enable` comments that wrapped it.

### Keep these 15 `map_*` methods + 3 helpers

```
map_access_types
map_alternative_identifier
map_catalogue
map_categories
map_contact
map_datasource_classification
map_hosting_legal_entity
map_jurisdiction
map_legal_statuses
map_link                                # trimmed above
map_nodes
map_order_type
map_provider
map_scientific_domains
map_trl

# Helpers (keep as-is)
object_status
fetch_ppid
# new per D17 (add in this slice):
extract_public_contact_emails
```

### Add helper for D17

Append to `importable.rb`:

```ruby
def extract_public_contact_emails(raw)
  Array(raw).map { |c| c.is_a?(Hash) ? c["email"] : c }.map { |e| e.to_s.strip }.reject(&:blank?).uniq
end
```

---

## A3. Update VOCABULARY_TYPES constant (15 min)

**File:** `config/initializers/constants.rb`

### Remove these 17 keys (delete the whole hash entries)

```
access_mode
area_of_activity
entity_type
entity_type_scheme
esfri_domain
esfri_type
funding_body
funding_program
life_cycle_status
marketplace_location
meril_scientific_domain
network
product_access_policy                  # maps to Vocabulary::ResearchProductAccessPolicy
provider_life_cycle_status
service_category
societal_grand_challenge
structure_type
```

### Keep (9 keys)

```
access_type
bundle_capability_of_goal
bundle_goal
datasource_classification
hosting_legal_entity                   # per D7
jurisdiction
legal_status                           # per D7
node
target_user                            # per D8
trl
```

(Count is 10 — `target_user` retained per D8 for future TrainingResource use in Slice I.)

---

## A4. Update ACCEPTED_VOCABULARIES (15 min)

**File:** `lib/import/vocabularies.rb`

### Remove these 20 keys

```
ACCESS_MODE
DS_COAR_ACCESS_RIGHTS_1_0              # covers both ResearchProductAccessPolicy + MetadataAccessPolicy
DS_PERSISTENT_IDENTITY_SCHEME          # per D9
DS_RESEARCH_ENTITY_TYPE                # per D9
FUNDING_BODY
FUNDING_PROGRAM
LIFE_CYCLE_STATUS
MARKETPLACE_LOCATION
PROVIDER_AREA_OF_ACTIVITY
PROVIDER_ESFRI_DOMAIN
PROVIDER_ESFRI_TYPE
PROVIDER_LIFE_CYCLE_STATUS
PROVIDER_MERIL_SCIENTIFIC_DOMAIN
PROVIDER_MERIL_SCIENTIFIC_SUBDOMAIN
PROVIDER_NETWORK
PROVIDER_SOCIETAL_GRAND_CHALLENGE
PROVIDER_STRUCTURE_TYPE
RELATED_PLATFORM
SERVICE_CATEGORY
SUPERCATEGORY                          # per D10 — not served by V6 vocab API
```

### Keep (12 keys)

```
CATEGORY
SUBCATEGORY
SCIENTIFIC_DOMAIN
SCIENTIFIC_SUBDOMAIN
TRL
ACCESS_TYPE
NODE
TARGET_USER                            # per D8
DS_JURISDICTION
DS_CLASSIFICATION
PROVIDER_LEGAL_STATUS                  # per D7
PROVIDER_HOSTING_LEGAL_ENTITY          # per D7
```

All 12 are served by `GET /vocabulary/byType`: `CATEGORY`=20, `SUBCATEGORY`=179, `TARGET_USER`=18, the rest standard.

Note: `COUNTRY` is NOT in `ACCEPTED_VOCABULARIES` (fetched via separate endpoint). Do not add it.

---

## A5. Delete vocabulary specs and factories (15 min)

Delete spec files for each model deleted in A1. Locations:

- `spec/models/vocabulary/{access_mode,area_of_activity,entity_type,entity_type_scheme,esfri_domain,esfri_type,funding_body,funding_program,life_cycle_status,marketplace_location,meril_scientific_domain,network,provider_life_cycle_status,research_product_access_policy,research_product_metadata_access_policy,service_category,societal_grand_challenge,structure_type}_spec.rb`
- `spec/models/platform_spec.rb`, `spec/models/service_relationship_spec.rb`, `spec/models/required_service_relationship_spec.rb`, `spec/models/manual_service_relationship_spec.rb`
- `spec/models/link/{use_cases_url,research_product_license_url,research_product_metadata_license_url}_spec.rb`

Delete factories for the same models in `spec/factories/vocabularies/`, `spec/factories/platforms.rb`, `spec/factories/service_relationships.rb`, `spec/factories/links.rb` (remove relevant blocks only).

Do NOT delete `target_user` specs/factories (kept per D8).

Search for remaining references and delete them:

```bash
grep -rln "Vocabulary::AccessMode\|Vocabulary::FundingBody\|Vocabulary::FundingProgram\|Vocabulary::LifeCycleStatus\|Vocabulary::ProviderLifeCycleStatus\|Vocabulary::Network\b\|Vocabulary::StructureType\|Vocabulary::EsfriDomain\|Vocabulary::EsfriType\|Vocabulary::MerilScientific\|Vocabulary::AreaOfActivity\|Vocabulary::SocietalGrandChallenge\|Vocabulary::MarketplaceLocation\|Vocabulary::ServiceCategory\|Vocabulary::EntityType\b\|Vocabulary::EntityTypeScheme\|Vocabulary::ResearchProductAccessPolicy\|Vocabulary::ResearchProductMetadataAccessPolicy\|\bPlatform\b\|ServiceRelationship\|ManualServiceRelationship\|RequiredServiceRelationship\|Link::UseCasesUrl\|Link::ResearchProductLicenseUrl\|Link::ResearchProductMetadataLicenseUrl" spec/
```

Every hit must be either deleted or updated to remove the reference.

---

## A6. DB migration — drop vocabulary data (30 min)

**File:** `db/migrate/XXXXXX_remove_v5_vocabularies.rb`

```ruby
class RemoveV5Vocabularies < ActiveRecord::Migration[7.2]
  REMOVED_VOCAB_TYPES = %w[
    Vocabulary::AccessMode
    Vocabulary::AreaOfActivity
    Vocabulary::EntityType
    Vocabulary::EntityTypeScheme
    Vocabulary::EsfriDomain
    Vocabulary::EsfriType
    Vocabulary::FundingBody
    Vocabulary::FundingProgram
    Vocabulary::LifeCycleStatus
    Vocabulary::MarketplaceLocation
    Vocabulary::MerilScientificDomain
    Vocabulary::Network
    Vocabulary::ProviderLifeCycleStatus
    Vocabulary::ResearchProductAccessPolicy
    Vocabulary::ResearchProductMetadataAccessPolicy
    Vocabulary::ServiceCategory
    Vocabulary::SocietalGrandChallenge
    Vocabulary::StructureType
  ].freeze

  def up
    execute "DELETE FROM provider_vocabularies   WHERE vocabulary_type IN (#{quoted(REMOVED_VOCAB_TYPES)})"
    execute "DELETE FROM service_vocabularies    WHERE vocabulary_type IN (#{quoted(REMOVED_VOCAB_TYPES)})"
    execute "DELETE FROM catalogue_vocabularies  WHERE vocabulary_type IN (#{quoted(REMOVED_VOCAB_TYPES)})"
    execute "DELETE FROM persistent_identity_system_vocabularies WHERE vocabulary_type IN (#{quoted(REMOVED_VOCAB_TYPES)})"
    execute "DELETE FROM vocabularies WHERE type IN (#{quoted(REMOVED_VOCAB_TYPES)})"

    drop_table :service_target_users, if_exists: true
    drop_table :service_related_platforms, if_exists: true
    drop_table :service_relationships, if_exists: true
    drop_table :platforms, if_exists: true
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def quoted(arr)
    arr.map { |v| ActiveRecord::Base.connection.quote(v) }.join(",")
  end
end
```

Note: `persistent_identity_systems` (the parent table) AND `persistent_identity_system_vocabularies` are both dropped in **Slice D1** per D9 (V6 API no longer sends the field). This Slice A migration only removes `service_relationships`, `platforms`, `service_target_users`, `service_related_platforms`. `service_target_users` is dropped because V6 Service no longer references `target_users` even though the `TargetUser` model itself is kept per D8 (TrainingResource re-uses it via a new join in Slice I).

---

## Validate

```bash
bundle exec rails db:migrate
bundle exec rails runner "puts Vocabulary.distinct.pluck(:type).sort"
# Expect exactly:
#   Vocabulary::AccessType
#   Vocabulary::BundleCapabilityOfGoal
#   Vocabulary::BundleGoal
#   Vocabulary::DatasourceClassification
#   Vocabulary::HostingLegalEntity
#   Vocabulary::Jurisdiction
#   Vocabulary::LegalStatus
#   Vocabulary::Node
#   Vocabulary::Trl

# Deleted vocab files:
ls app/models/vocabulary/{access_mode,area_of_activity,entity_type,entity_type_scheme,esfri_domain,esfri_type,funding_body,funding_program,life_cycle_status,marketplace_location,meril_scientific_domain,network,provider_life_cycle_status,research_product_access_policy,research_product_metadata_access_policy,service_category,societal_grand_challenge,structure_type}.rb 2>&1 | grep -c "No such file"
# Should return 18

# Importable map_ count (15 methods):
grep -c "^  def map_" app/models/concerns/importable.rb
# Should return 15

# map_link must not reference deleted Link classes:
grep -E "Link::(UseCasesUrl|ResearchProductLicenseUrl|ResearchProductMetadataLicenseUrl)" app/models/concerns/importable.rb
# Should return empty

# Vocab import dry-run:
DRY_RUN=true bundle exec rake import:vocabularies
# Should complete without NameError/NoMethodError

# App boots:
bundle exec rails runner "puts 'OK'"
```

**Commit.** This is a clean, reversible checkpoint.
