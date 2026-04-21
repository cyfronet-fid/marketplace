# EOSC Marketplace: V5 to V6 Migration Guide

A ground-up walkthrough for anyone joining this migration. No prior codebase knowledge assumed.

---

## Table of Contents

1. [What is this system?](#1-what-is-this-system)
2. [The two systems: Marketplace and Provider Catalogue](#2-the-two-systems-marketplace-and-provider-catalogue)
3. [How data flows through the system](#3-how-data-flows-through-the-system)
4. [The domain model (V5 — current)](#4-the-domain-model-v5--current)
5. [What V6 changes and why](#5-what-v6-changes-and-why)
6. [The domain model (V6 — target)](#6-the-domain-model-v6--target)
7. [How the import pipeline works](#7-how-the-import-pipeline-works)
8. [How real-time sync works (JMS and AMS)](#8-how-real-time-sync-works-jms-and-ams)
9. [The data lifecycle end-to-end](#9-the-data-lifecycle-end-to-end)
10. [Key code locations](#10-key-code-locations)
11. [What the migration actually involves](#11-what-the-migration-actually-involves)
12. [Reading order for the slice files](#12-reading-order-for-the-slice-files)

---

## 1. What is this system?

The **EOSC Marketplace** is a Rails 7.2 web application where researchers discover, compare, and order research services — things like cloud computing, data storage, training platforms, and scientific instruments provided by organisations across Europe.

Think of it as an app store, but for research infrastructure. A scientist can:

- Browse and search services
- Compare them side-by-side
- Add them to a project
- Place orders (routed to a JIRA ticketing system)
- Leave ratings and opinions

The app is backed by PostgreSQL, Elasticsearch (via Searchkick), Redis, Sidekiq for background jobs, and ActiveMQ for messaging.

---

## 2. The two systems: Marketplace and Provider Catalogue

The Marketplace does **not** manage its own catalogue of services. That responsibility belongs to a separate system: the **Provider Catalogue (PC)**, maintained by the Athena team.

```
┌──────────────────────────┐         ┌──────────────────────────┐
│    Provider Catalogue    │         │     EOSC Marketplace     │
│        (Athena)          │         │      (this codebase)     │
│                          │         │                          │
│  - Organisations register│  ───►   │  - Imports PC data       │
│  - Services are reviewed │  sync   │  - Adds ordering layer   │
│  - Vocabularies defined  │         │  - User projects, JIRA   │
│  - Datasources managed   │         │  - Search, compare       │
│                          │         │  - Ratings, favourites   │
└──────────────────────────┘         └──────────────────────────┘
```

**The PC is the source of truth.** The Marketplace is a downstream consumer. This relationship is central to understanding the codebase — and to understanding why a schema change in the PC (V5 → V6) forces a migration in the Marketplace.

The PC exposes a REST API and publishes real-time events via messaging. The Marketplace consumes both.

---

## 3. How data flows through the system

There are three data flow paths. All three are affected by the migration.

### Path 1: Batch import (rake tasks)

Run manually or on a schedule. Fetches all records from the PC API and creates/updates local copies.

```
PC REST API                    Marketplace
   │
   │  GET /public/provider/bundle
   │  GET /public/service/all
   │  GET /public/datasource/all          lib/import/providers.rb
   │  GET /public/deployableService       lib/import/resources.rb
   │  GET /vocabulary/byType              lib/import/datasources.rb
   │                                      lib/import/deployable_services.rb
   ▼                                      lib/import/vocabularies.rb
                                               │
                               Importers::Request (HTTP client)
                                               │
                               Importers::Provider.call(json)
                               Importers::Service.call(json)    ◄── JSON → model attrs
                               Importers::Datasource.call(json)
                                               │
                               Provider::Create / Service::Update  ◄── persist to DB
                                               │
                               Searchkick reindex                  ◄── update Elasticsearch
```

### Path 2: Real-time sync (JMS/AMS messaging)

The PC publishes events when resources change. The Marketplace subscribes and processes them asynchronously.

```
PC publishes event                     Marketplace
   │
   │  topic: provider.update           Jms::Subscriber (STOMP)
   │  topic: service.create            Ams::Subscriber (HTTP pull)
   │  payload: { provider: {...} }          │
   │                                        ▼
   │                               Jms::ManageMessage / Ams::ManageMessage
   │                                   (parse topic → route to job)
   │                                        │
   │                                        ▼
   │                               Provider::PcCreateOrUpdateJob  (Sidekiq)
   │                                        │
   │                                        ▼
   │                               Provider::PcCreateOrUpdate     (service object)
   │                                   uses Importers::Provider   (same mapper as batch)
   │                                        │
   │                                        ▼
   │                               DB save → Propagable concern → Ess::Add → ESS sync
```

### Path 3: ESS sync (Marketplace → EOSC Search Service)

After any local change, the Marketplace pushes serialised data to the EOSC Search Service (ESS), a separate search engine.

```
Provider saved in DB
       │
       ▼
  Propagable concern (after_save callback)
       │
       ▼
  Ess::Add.call(provider, "provider")
       │
       ▼
  Ess::ProviderSerializer.new(provider).as_json   ◄── what fields get sent
       │
       ▼
  Ess::UpdateJob (Sidekiq, queue: ess_update)
       │
       ▼
  HTTP POST to ESS endpoint
```

**The V6 migration affects all three paths**: the API endpoints change, the JSON fields change, the messaging topics rename, and the serialised output must match the new schema.

---

## 4. The domain model (V5 — current)

### Core entities

```
                    ┌───────────┐
                    │ Catalogue │  Groups of providers
                    └─────┬─────┘
                          │ has_many
                    ┌─────▼─────┐
                    │ Provider  │  Organisation offering services
                    └─────┬─────┘
                          │ has_many (via service_providers + resource_organisation)
                    ┌─────▼─────┐
                    │  Service  │  The main resource entity
                    └─────┬─────┘
                          │ STI subclass
                    ┌─────▼──────┐
                    │ Datasource │  A Service that is a data repository
                    └────────────┘

  ┌───────────────────┐
  │ DeployableService  │  Separate table, deployable infrastructure templates
  └───────────────────┘

  ┌───────────┐
  │ Guideline │  Interoperability records, linked to Services
  └───────────┘
```

### How ordering works (not affected by V6)

```
User creates a Project
       │
       ▼
Project has many ProjectItems
       │
       ▼
ProjectItem belongs to an Offer
       │
       ▼
Offer belongs to a Service (or DeployableService)
       │
       ▼
Order routed to JIRA
```

This ordering side is **not affected** by the V6 migration. It's worth knowing it exists so you don't accidentally break it, but you won't need to change it.

### V5 Provider: ~40 fields

The V5 Provider is heavy. A single Provider record touches:

| Area           | Fields                                                                                 |
| -------------- | -------------------------------------------------------------------------------------- |
| Identity       | name, abbreviation, pid, website, description, logo                                    |
| Address        | street, postal code, city, region, country                                             |
| Classification | scientific domains (join table), tags (acts_as_taggable), structure types (vocabulary) |
| Maturity       | life cycle status (vocabulary), certifications (array)                                 |
| Dependencies   | participating countries, affiliations, networks (vocabulary)                           |
| ESFRI/MERIL    | esfri domains, esfri type, MERIL scientific domains (vocabularies)                     |
| Other          | areas of activity, societal grand challenges, national roadmaps (vocabularies)         |
| Contacts       | main contact (structured), public contacts (structured), data administrators           |
| Legal          | legal entity, legal status (vocabulary), hosting legal entity (vocabulary)             |

Each vocabulary association goes through a `provider_vocabularies` polymorphic join table.

### V5 Service: ~60 fields

Even heavier. Includes everything from availability (geographic, language) to financial (payment model, pricing), management URLs (helpdesk, monitoring, training), maturity info, funding attribution, related/required services, and more.

### Vocabularies: ~30 types

Controlled vocabularies are stored as STI subclasses of a `Vocabulary` base model:

```ruby
Vocabulary::Trl # Technology Readiness Level
Vocabulary::AccessType # open_access, etc.
Vocabulary::FundingBody # EU funding bodies
Vocabulary::EsfriDomain # ESFRI research domains
Vocabulary::MerilScientificDomain # MERIL classification
Vocabulary::Network # Provider networks
# ... ~25 more types
```

These are imported from the PC via `vocabulary/byType` API and linked to Providers/Services via join tables (`provider_vocabularies`, `service_vocabularies`).

---

## 5. What V6 changes and why

The V6 profile schema is a **massive simplification** driven by the EOSC-Beyond project. The motivation:

1. **Too many fields nobody fills in.** Most of the 40 Provider fields and 60 Service fields are optional and usually empty. They create UI complexity without adding value.
2. **Renames to match EOSC terminology.** "Provider" becomes "Organisation." "Deployable Software" becomes "Deployable Application."
3. **New entity types.** Adapter and TrainingResource are first-class resources now.
4. **Datasource becomes a Service type.** Rather than a separate registration flow, a Datasource is registered as a Service with a special PID prefix.
5. **Contacts simplified.** Structured contacts (first name, last name, phone, position) become simple email arrays.

### The scale of the change

| Entity                    | V5 fields | V6 fields | Reduction |
| ------------------------- | --------- | --------- | --------- |
| Provider (→ Organisation) | ~40       | ~15       | 62%       |
| Service                   | ~60       | ~25       | 58%       |
| Datasource                | ~12 extra | ~4 extra  | 67%       |
| Vocabularies              | ~30 types | ~12 types | 60%       |

---

## 6. The domain model (V6 — target)

### Organisation (was Provider) — 15 fields

```
kept:     id, name, abbreviation, website, country, legal_entity,
          legal_status, hosting_legal_entity, description, logo,
          multimedia, node_pid
new:      public_contacts (email array), alternative_pids
removed:  entire address, scientific domains, tags, structure types,
          life cycle status, certifications, networks, ESFRI everything,
          MERIL everything, areas of activity, grand challenges,
          national roadmaps, main contact (structured), data administrators
```

### Service (extends EOSC Resource) — 25 fields

```
kept:     id, name, description, webpage, logo, scientific_domains,
          categories, tags, access_types, trl, terms_of_use,
          privacy_policy, access_policy, order_type, order
new:      urls (array), publishing_date, type, resource_owner,
          node_pid, public_contacts (emails), jurisdiction, service_providers
removed:  tagline, multimedia, use_cases, service_categories, horizontal,
          marketplace_locations, target_users, access_modes,
          geographical/language availability, life_cycle_status,
          certifications, standards, open_source_technologies,
          version, changelog, all management URLs, all financial fields,
          funding bodies/programs, grant_project_names,
          helpdesk/security email, main_contact, abbreviation
```

### Key renames

| V5                               | V6                             |
| -------------------------------- | ------------------------------ |
| Provider                         | Organisation                   |
| Deployable Software/Service      | Deployable Application         |
| `resourceOrganisation`           | `resourceOwner`                |
| `resourceProviders`              | `serviceProviders`             |
| `node`                           | `nodePID`                      |
| `mainContact` + `publicContacts` | `publicContacts` (emails only) |

### Vocabularies removed (~18 types)

```
AreaOfActivity, SocietalGrandChallenge, StructureType,
EsfriDomain, EsfriType, MerilScientificDomain, Network,
ProviderLifeCycleStatus, LifeCycleStatus, AccessMode,
FundingBody, FundingProgram, MarketplaceLocation, ServiceCategory,
EntityType, EntityTypeScheme,
ResearchProductAccessPolicy, ResearchProductMetadataAccessPolicy
```

### New entity types

```
Adapter             — links a Service to deployable software packages
TrainingResource    — learning materials tied to Services
InteroperabilityGuideline — extended from existing Guideline model
```

---

## 7. How the import pipeline works

This section walks through the code path for a batch Provider import, step by step. Understanding this one path deeply will let you reason about all the others (Service, Datasource, etc. follow the same pattern).

### Step 1: Rake task entry point

```ruby
# lib/tasks/import.rake
task providers: :environment do
  Import::Providers.new(
    ENV.fetch("MP_IMPORT_EOSC_REGISTRY_URL", "https://integration.providers.sandbox.eosc-beyond.eu/api")
    # ... options
  ).call
end
```

The base URL points to the PC API. All import tasks share this env var.

### Step 2: Orchestrator fetches data

```ruby
# lib/import/providers.rb
def external_providers_data
  @token ||= Importers::Token.new(faraday: @faraday).receive_token
  rp =
    Importers::Request.new(
      @eosc_registry_base_url,
      "public/provider/bundle", # ← V5 endpoint, changes in V6
      faraday: @faraday,
      token: @token
    ).call
  rp.body["results"]
end
```

`Importers::Token` obtains an OAuth access token using a refresh token flow against the EOSC AAI. `Importers::Request` is a thin Faraday HTTP wrapper.

### Step 3: Mapper transforms JSON to model attributes

```ruby
# app/services/importers/provider.rb
def call
  {
    pid: @data["id"],
    name: @data["name"],
    scientific_domains: map_scientific_domains(domains), # ← removed in V6
    tag_list: Array(@data["tags"]), # ← removed in V6
    street_name_and_number: location["streetNameAndNumber"], # ← removed in V6
    networks: map_networks(networks), # ← removed in V6
    main_contact: MainContact.new(map_contact(@data["mainContact"])) # ← removed
    # ... 40 more fields
  }
end
```

This is the heart of the migration. Every field mapped here from the PC JSON must match the V6 response format. Fields removed from V6 must be stripped. New fields must be added. Renames (like `resourceOrganisation` → `resourceOwner`) must be reflected.

The `map_*` helper methods live in the `Importable` concern (`app/models/concerns/importable.rb`). They convert PC vocabulary EIDs into local Vocabulary model instances, e.g.:

```ruby
def map_networks(networks)
  Vocabulary::Network.where(eid: networks) # ← Vocabulary::Network deleted in V6
end
```

### Step 4: Orchestrator persists

```ruby
# lib/import/providers.rb (simplified)
if current_provider.blank?
  create_provider(parsed_provider_data, logo_url, eid)
else
  update_provider(current_provider, parsed_provider_data, logo_url)
end
```

The create path: saves the Provider, creates a `ProviderSource` record (linking the local record to the PC EID), and downloads the logo via `Importers::Logo`.

The `*Source` models (`ProviderSource`, `ServiceSource`, etc.) track which PC record each local record came from, using:

- `eid` — the PC entity ID (like `"cyfronet"`)
- `source_type` — always `"eosc_registry"`

A Provider's `upstream_id` foreign key points to its `ProviderSource`, indicating that the PC is the authoritative source for that record.

### Step 5: After save — ESS sync

The `Propagable` concern fires `after_save`:

```ruby
module Propagable
  included { after_save :propagate_to_ess }

  def propagate_to_ess
    public? && !destroyed? ? Ess::Add.call(self, propagable_type) : Ess::Delete.call(id, propagable_type)
  end
end
```

This serialises the record using `Ess::ProviderSerializer` and POSTs it to the EOSC Search Service. The serializer defines exactly which fields leave the Marketplace — so it must also be updated for V6.

---

## 8. How real-time sync works (JMS and AMS)

There are **two** parallel messaging systems. Both do the same thing — receive resource change events from the PC and process them. They exist because the infrastructure is migrating from JMS to AMS.

### JMS (STOMP/ActiveMQ)

```ruby
# lib/jms/subscriber.rb
# Connects via STOMP protocol to ActiveMQ
# Subscribes to topics like: /topic/provider.>
# On message arrival:
Jms::ManageMessage.call(msg, eosc_registry_base_url, logger, token)
```

```ruby
# app/services/jms/manage_message.rb
# Parses the topic destination: "registry.provider.update"
# Routes by resource_type:
case resource_type
when "provider"
  Provider::PcCreateOrUpdateJob.perform_later(resource, status, modified_at)
when "service", "infra_service"
  Service::PcCreateOrUpdateJob.perform_later(resource, url, status, modified_at, token)
when "catalogue"
  Catalogue::PcCreateOrUpdateJob.perform_later(resource, status, modified_at)
when "datasource"
  Datasource::PcCreateOrUpdateJob.perform_later(hash, status)
when "deployable_service"
  DeployableService::PcCreateOrUpdateJob.perform_later(hash, status)
  # NOTE: no guideline/interoperability_record routing in JMS (gap to fix)
end
```

### AMS (HTTP pull from ARGO Messaging Service)

```ruby
# lib/ams/subscriber.rb
# Polls an HTTP endpoint for messages
# Topics configured in config/ams_subscriber.yml:
#   mp-provider-create, mp-provider-update, mp-service-delete, etc.
```

```ruby
# app/services/ams/manage_message.rb
# Same routing logic as JMS, but parses topic from AMS format
# DOES handle guideline/interoperability_record (unlike JMS)
```

### Config files

```yaml
# config/stomp_subscriber.yml — JMS connection settings
# config/ams_subscriber.yml — AMS pull URLs and topic list
```

### What V6 changes here

1. **Topic renames:** `provider.*` → `organisation.*`, `deployable_software.*` → `deployable_application.*`
2. **Both dispatchers** (`jms/manage_message.rb` AND `ams/manage_message.rb`) need updated routing
3. **AMS config** (`config/ams_subscriber.yml`) topic names need renaming
4. **New topics** for Adapter, TrainingResource

---

## 9. The data lifecycle end-to-end

Here's the complete picture of a Provider record's lifecycle:

```
1. REGISTRATION
   Organisation registers on the Provider Catalogue portal
   (external system, not our code)
        │
        ▼
2. BATCH IMPORT (or real-time JMS/AMS message)
   rake import:providers
        │
        ▼
3. Importers::Request fetches JSON from PC API
        │
        ▼
4. Importers::Provider maps JSON → Rails attributes hash
        │
        ▼
5. Import::Providers creates/updates Provider record
   Also creates ProviderSource (eid linkage)
   Also downloads logo via Importers::Logo
        │
        ▼
6. after_save → Propagable → Ess::Add
   Serialises via Ess::ProviderSerializer → POST to ESS
        │
        ▼
7. Searchkick reindex
   Provider.reindex updates Elasticsearch for Marketplace search
        │
        ▼
8. VISIBLE IN MARKETPLACE
   Public show page, search results, backoffice management
        │
        ▼
9. ONGOING SYNC
   JMS/AMS subscriber receives change events from PC
   → PcCreateOrUpdateJob → uses same Importers::Provider mapper
   → updates local record → Propagable → ESS sync
```

### Where each layer's code lives

| Layer                   | Directory                                                     |
| ----------------------- | ------------------------------------------------------------- |
| HTTP client             | `app/services/importers/request.rb`, `token.rb`               |
| JSON → attrs mappers    | `app/services/importers/{provider,service,datasource,...}.rb` |
| Shared mapping helpers  | `app/models/concerns/importable.rb`                           |
| Batch orchestrators     | `lib/import/{providers,resources,datasources,...}.rb`         |
| Rake entry points       | `lib/tasks/import.rake`                                       |
| JMS subscriber          | `lib/jms/subscriber.rb`                                       |
| AMS subscriber          | `lib/ams/subscriber.rb`                                       |
| JMS message dispatcher  | `app/services/jms/manage_message.rb`                          |
| AMS message dispatcher  | `app/services/ams/manage_message.rb`                          |
| Real-time create/update | `app/services/{provider,service,...}/pc_create_or_update.rb`  |
| Background jobs         | `app/jobs/{provider,service,...}/pc_create_or_update_job.rb`  |
| ESS serializers         | `app/serializers/ess/{provider,service,...}_serializer.rb`    |
| ESS sync                | `app/services/ess/{add,update,delete}.rb`                     |
| Domain models           | `app/models/{provider,service,datasource,...}.rb`             |
| Vocabulary models       | `app/models/vocabulary/*.rb`                                  |
| Source linkage models   | `app/models/{provider,service,...}_source.rb`                 |
| Backoffice forms        | `app/views/backoffice/{providers,services}/form/*.html.haml`  |
| Public views            | `app/views/{providers,services}/*.html.haml`                  |
| API serializers         | `app/serializers/api/v1/*.rb`                                 |
| Search config           | `app/models/service/search.rb`                                |
| Policies                | `app/policies/backoffice/{provider,service}_policy.rb`        |

---

## 10. Key code locations

### Files you'll touch most

| File                                         | Why                                                                              |
| -------------------------------------------- | -------------------------------------------------------------------------------- |
| `app/models/provider.rb`                     | ~300 lines. All associations, validations, wizard steps. Massive cleanup needed. |
| `app/models/service.rb`                      | ~350 lines. Even more associations. STI base for Datasource.                     |
| `app/models/concerns/importable.rb`          | ~215 lines. 37 `map_*` methods, ~22 being deleted.                               |
| `app/services/importers/provider.rb`         | 82 lines → ~30. JSON field mapping.                                              |
| `app/services/importers/service.rb`          | 121 lines → ~50. JSON field mapping.                                             |
| `app/services/jms/manage_message.rb`         | Topic routing. Add new types, rename existing.                                   |
| `app/services/ams/manage_message.rb`         | Same routing, different transport. Must stay in sync with JMS.                   |
| `config/ams_subscriber.yml`                  | Topic subscription list. 18 entries to rename.                                   |
| `app/serializers/ess/provider_serializer.rb` | ~48 lines. Strip to V6 fields.                                                   |
| `app/serializers/ess/service_serializer.rb`  | ~92 lines. Strip to V6 fields.                                                   |
| `config/initializers/constants.rb`           | `VOCABULARY_TYPES` hash — remove ~18 entries.                                    |
| `lib/import/vocabularies.rb`                 | `ACCEPTED_VOCABULARIES` hash — remove ~20 entries.                               |

### Files you might forget

| File                                                       | Why                                                        |
| ---------------------------------------------------------- | ---------------------------------------------------------- |
| `app/services/ams/manage_message.rb`                       | Easy to forget — same logic as JMS but separate file       |
| `config/ams_subscriber.yml`                                | Topic names hardcoded here                                 |
| `db/data.yml`, `db/data_e2e.yml`                           | Seed data references V5 fields                             |
| `app/models/concerns/propagable.rb`                        | Triggers ESS sync on save — must work with new serializers |
| `app/models/persistent_identity_system.rb`                 | References deleted vocabulary types                        |
| `app/policies/backoffice/{platform,target_user}_policy.rb` | Policies for deleted models                                |
| `test/system/cypress/e2e/provider_portal/`                 | Cypress E2E tests referencing V5 fields                    |

### The wizard system

Provider registration in the backoffice uses a multi-step wizard:

```ruby
# app/helpers/backoffice/providers_helper.rb
BASIC_STEPS = %w[profile location contacts managers summary]
EXTENDED_STEPS = %w[profile classification location contacts maturity dependencies managers other]
```

The `WizardFormModel` concern (`app/controllers/concerns/wizard_form_model.rb`) drives step navigation. Each step maps to a form partial in `app/views/backoffice/providers/form/`. V6 eliminates the `classification`, `maturity`, `dependencies`, and `other` steps entirely.

---

## 11. What the migration actually involves

### The domino effect

One schema change in the PC triggers a cascade through every layer:

```
PC V6 schema change
  │
  ├─► DB migrations (drop columns, add columns, drop join tables)
  │
  ├─► Model updates (remove associations, validations, concerns)
  │
  ├─► Importer rewrites (new JSON field mappings)
  │
  ├─► Importable concern cleanup (delete ~22 dead map_* methods)
  │
  ├─► Vocabulary model deletion (~18 model files)
  │
  ├─► Message dispatcher updates (JMS + AMS topic renames)
  │
  ├─► AMS config updates (topic subscription list)
  │
  ├─► PcCreateOrUpdate service updates (field mapping)
  │
  ├─► ESS serializer updates (output field list)
  │
  ├─► Backoffice form removal (wizard steps, form partials)
  │
  ├─► Public view updates (show pages, search filters)
  │
  ├─► Policy updates (permitted_attributes)
  │
  ├─► Elasticsearch search_data updates (indexed fields, facets)
  │
  ├─► API serializer updates
  │
  ├─► Factory updates (FactoryBot test fixtures)
  │
  ├─► Spec updates (model, importer, controller, feature tests)
  │
  └─► Seed data updates (db/data.yml, db/data_e2e.yml)
```

### What does NOT change

- **Ordering system** (Offers, Bundles, ProjectItems, JIRA integration)
- **Authentication** (EGI Check-in, OmniAuth)
- **User model, user dashboard**
- **Recommender integration**
- **Monitoring integration**
- **The Rails app structure itself** (routes, controllers, namespaces)

### Work is organised into slices, not phases

The slice-based plan (see `README.md` Effort Summary and `slices/` directory) is the authoritative decomposition. Each slice is a vertical cut through one entity type, covering DB through views in a single committable unit. See slice files for details and day estimates.

---

## 12. Reading order for the slice files

If you're implementing this, read the slices in this order:

### Start here (understand the scope)

1. **This file** — you're here
2. `README.md` — the overview with effort estimates and open questions

### Implementation order

3. `slices/slice-0-coordination.md` — resolve open questions first
4. `slices/slice-a-vocabularies.md` — dependency for everything else, clean standalone cut
5. `slices/slice-b-provider.md` — first full entity, validates the pattern
6. `slices/slice-c-service.md` — largest entity, includes Elasticsearch search changes
7. `slices/slice-d-datasource.md` — small, DS-specific changes on top of Service
8. `slices/slice-e-deployable-service.md` — rename to DeployableApplication
9. `slices/slice-f-catalogue.md` — blocked on Athena confirming V6 Catalogue schema
10. `slices/slice-g-messaging.md` — cross-cutting JMS + AMS topic renames
11. `slices/slice-h-guideline.md` — extend existing Guideline model
12. `slices/slice-i-new-entities.md` — Adapter + TrainingResource _(deferrable)_
13. `slices/slice-j-integration.md` — integration testing, cleanup, deploy

### General principle

**Work from the bottom up.** Within each slice: DB migrations first, then models, then importers, then views. Each layer depends on the one below it. If you try to update a view before updating the model, you'll reference associations that no longer exist.

**Test each slice before moving on.** Each slice file has a `Validate` section with specific commands. Commit after each green slice.

---

## Appendix: Quick glossary

| Term           | Meaning                                                                          |
| -------------- | -------------------------------------------------------------------------------- |
| **PC**         | Provider Catalogue — the external system that manages the service registry       |
| **ESS**        | EOSC Search Service — the external search engine we sync data to                 |
| **EID**        | External ID — the identifier used by the PC for a resource                       |
| **PID**        | Persistent Identifier — the canonical identifier for a resource                  |
| **PPID**       | Persistent PID — an alternative EOSC PID scheme                                  |
| **JMS**        | Java Message Service — legacy messaging via STOMP/ActiveMQ                       |
| **AMS**        | ARGO Messaging Service — new messaging via HTTP pull/push                        |
| **STI**        | Single Table Inheritance — Datasource inherits from Service in the same DB table |
| **Searchkick** | Ruby gem wrapping Elasticsearch                                                  |
| **Propagable** | Concern that auto-syncs records to ESS on save                                   |
| **Importable** | Concern with ~25 helper methods for mapping PC vocabulary EIDs to local models   |
| **Upstream**   | The `*Source` record indicating this record is managed by the PC                 |
| **Vocabulary** | Controlled enumeration (TRL, AccessType, etc.) imported from PC                  |
| **Backoffice** | Admin/provider management interface at `/backoffice`                             |
