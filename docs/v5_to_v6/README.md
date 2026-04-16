# V5 → V6 Profile Migration Plan

**Issue:** [#3635](https://github.com/cyfronet-fid/marketplace/issues/3635)  
**Source:** [eosc-resources-model](https://github.com/EOSC-PLATFORM/eosc-resources-model)  
**Dev API:** `https://dev.providers.sandbox.eosc-beyond.eu/api`  
**Integration API:** `https://integration.providers.sandbox.eosc-beyond.eu/api` (20 orgs, 66 services)  
**Integration Swagger (V6)**: [integration.json](./swagger/integration.json)  
**Dev Swagger (V6)**: [integration.json](./swagger/dev.json)  
**Prod Swagger (still V5)**: [integration.json](./swagger/prod.json)

## TL;DR

V6 is a massive simplification. Organisation (was Provider) drops from ~40 to ~15 fields. Service loses entire sections (availability, management, financial, attribution). Datasource becomes a standalone Service type with own PID prefix. New entity types: Adapter, TrainingResource, InteroperabilityGuideline. JMS topics renamed.

## Effort Summary

| Slice                                | Days     | Cumulative |
| ------------------------------------ | -------- | ---------- |
| 0. Coordination                      | 0.5      | 0.5        |
| A. Vocabularies + Importable cleanup | 1        | 1.5        |
| B. Provider end-to-end               | 2        | 3.5        |
| C. Service end-to-end                | 2.5      | 6          |
| D. Datasource                        | 0.5      | 6.5        |
| E. DeployableService                 | 0.5      | 7          |
| F. Catalogue                         | 0.5      | 7.5        |
| G. Messaging (JMS + AMS)             | 1.5      | 9          |
| H. Guideline                         | 1        | 10         |
| I. New entities _(deferrable)_       | 4        | 14         |
| J. Integration + cleanup + deploy    | 2.5      | 16.5       |
| **Total**                            | **16.5** |            |
| **Without new entity types**         | **12.5** |            |

With coordination buffer: **~4 weeks** total, or **~3 weeks** if Adapter/TrainingResource deferred.

First validation checkpoint at **1.5 days** (Slice A). Working partial system at **3.5 days** (after Slice B).

## Key Context (from Athena, April 2026)

- **Renames:** Provider → Organisation, Deployable Software → Deployable Application
- **Endpoints:** `/organisation/` is new, `/provider/` kept alongside for now. `/deployableApplication/` replaces `/deployableService/` (old endpoint returns 404)
- **Datasource → Service type:** Datasource is now registered as a Service with its own PID prefix. Migration of existing DS is deferred (per-owner consultation)
- **JMS topics renamed:** `provider.*` → `organisation.*`, `deployable_software.*` → `deployable_application.*`. New AMS topics/subscriptions needed. JMS kept for now
- **Date format:** ISO 8601 (`YYYY-MM-DD`) for `publishingDate`, `versionDate`, `lastUpdate`
- **Non-public resource IDs:** get `00` suffix appended (shouldn't affect MP if we fetch public only - verify)
- **`mainContact` and `users`** still present in API response (transitional) alongside new `publicContacts` (email array)

## Resolved Questions (see [slice-0-coordination.md](slices/slice-0-coordination.md) for decisions D1–D24)

| #   | Question                                                    | Resolution                                                                                                                            |
| --- | ----------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| D1  | Catalogue V6 schema                                         | `/catalogue/all` returns 200 with **V5-shaped** payload (no `/public/` variant exists); Slice F deferred until server emits V6 schema |
| D2  | `mainContact`/`users` removal date                          | Still returned 2026-04-16; importers ignore them                                                                                      |
| D3  | Archive vs. drop removed data                               | Drop by default; optional `ARCHIVE=true` task dumps to `tmp/`                                                                         |
| D4  | Existing Datasource migration                               | No renames; new DS carries whatever PC `id` returns                                                                                   |
| D5  | AMS topic names for Adapter/TR                              | `mp-adapter-*`, `mp-training_resource-*`                                                                                              |
| D7  | `legalStatus` / `hostingLegalEntity` storage                | Keep vocabulary models; API string IS the stored EID                                                                                  |
| D8  | `TARGET_USER` vocabulary                                    | KEEP — needed by TrainingResource `targetGroups` (Slice I)                                                                            |
| D9  | `DS_RESEARCH_ENTITY_TYPE` / `DS_PERSISTENT_IDENTITY_SCHEME` | DROP both — `researchProductTypes` stored as plain string array                                                                       |
| D10 | `SUPERCATEGORY` vocabulary                                  | REMOVE from `ACCEPTED_VOCABULARIES` (not served by V6)                                                                                |
| D11 | Datasource `"type": "DataSource"` capital-S                 | Explicit mapping in `Importers::Datasource`                                                                                           |
| D13 | `accessTypes` shape                                         | **API is inconsistent:** Service returns array, Datasource returns bare string. `Array()` wrap handles both                           |
| D20 | AMS cutover style                                           | Assume HARD CUT; alias table + dual-key body parse kept as safety net                                                                 |
| D24 | Slice I (Adapter + TR) scope                                | **Default: DEFER to follow-up PR.** `TargetUser` + 10 reserved vocabs stay in place                                                   |

Pending stakeholder input (D6, D12, D17–D23): see Slice 0 — defaults are safe to proceed without confirmation.

## API Endpoints Verified (2026-04-17)

All counts re-checked today against both sandboxes (`?quantity=1&from=0`, reading `total`). Field-level shapes re-sampled across the full integration population (20 orgs, 66 services, 2 datasources, 8 DAs, 3 adapters, 1 TR, 3 IRs) — see Slice 0 verification summary for the delta vs. 2026-04-16.

**Swagger caveat:** `docs/v5_to_v6/swagger/integration.json` (version `5.4.1-SNAPSHOT`) is useful as an endpoint inventory but CANNOT verify field shapes — every payload in `components.schemas` collapses to `{type: object, additionalProperties: {}}`. Field-level claims must be curled against a live env.

| Endpoint                                 | Dev       | Integration | Status                                 |
| ---------------------------------------- | --------- | ----------- | -------------------------------------- |
| `GET /public/organisation/all`           | 5         | 20          | Working                                |
| `GET /public/provider/all`               | 5         | 20          | Legacy alias, same data                |
| `GET /public/service/all`                | 1         | 66          | Working (integration was 68, now 66)   |
| `GET /public/datasource/all`             | 2         | 2           | Working                                |
| `GET /public/deployableApplication/all`  | 0         | 8           | Working                                |
| `GET /public/deployableService/all`      | 404       | 404         | **Removed** — old endpoint gone        |
| `GET /catalogue/all`                     | 5         | 5           | Unauth, **V5-shaped payload** (D1)     |
| `GET /public/catalogue/all`              | 404       | 404         | Never existed — no `/public/` variant  |
| `GET /catalogue/bundle/all`              | 403       | 403         | Admin-only (auth required)             |
| `GET /public/adapter/all`                | 1         | 3           | Working                                |
| `GET /public/trainingResource/all`       | 0         | 1           | Working                                |
| `GET /public/interoperabilityRecord/all` | 1         | 3           | Working                                |
| `GET /vocabulary/byType/{TYPE}`          | 200       | 200         | TRL, ACCESS_TYPE, DS_JURISDICTION etc. |
| `GET /vocabulary/byType/all`             | 500 error | 500 error   | Broken on **both** envs                |

## Slice Overview

Work is organised into slices A–J (see [slice files](slices/)). Each slice is a vertical cut that can be committed independently:

- **Slices A–F**: DB, models, importers, serializers, views — one per entity type
- **Slice G**: Cross-cutting messaging (JMS + AMS topic renames)
- **Slice H**: Guideline/InteroperabilityGuideline extension
- **Slice I** _(deferrable — D24 default: DEFER to follow-up PR)_: New entity types (Adapter, TrainingResource)
- **Slice J**: Integration testing, cleanup, deploy

## Key Schema Changes

### Organisation (was Provider) - ~14 MP-kept fields

**Kept:** id, name, abbreviation, website, country, legalEntity, legalStatus, hostingLegalEntity, description, logo, multimedia, nodePID
**New:** publicContacts (email array), alternativePIDs
**Transitional (ignored per D2):** mainContact, users — still returned by API, not consumed by MP
**Removed:** full address (street/postal/city/region), scientificDomains, tags, structureTypes, lifeCycleStatus, certifications, participatingCountries, affiliations, networks, esfriDomains/Type, merilScientificDomains, areasOfActivity, societalGrandChallenges, nationalRoadmaps, dataAdministrators (auto-population; manual via backoffice per D19)

### Service (extends EOSC Resource) - 25 fields

**Kept:** id, name, description, webpage, logo, scientificDomains, categories, tags, accessTypes, trl, termsOfUse, privacyPolicy, accessPolicy, orderType, order
**New:** urls (array), publishingDate, type, resourceOwner, nodePID, publicContacts (emails), jurisdiction (from DS), serviceProviders
**Removed:** tagline, multimedia, useCases, serviceCategories, horizontalService, marketplaceLocations, targetUsers, accessModes, geographicalAvailabilities, languageAvailabilities, resourceGeographicLocations, lifeCycleStatus, certifications, standards, openSourceTechnologies, version, lastUpdate, changeLog, requiredResources, relatedResources, relatedPlatforms, fundingBody, fundingPrograms, grantProjectNames, helpdeskPage, userManual, trainingInformation, statusMonitoring, maintenance, serviceLevel, paymentModel, pricing, helpdeskEmail, securityContactEmail, mainContact, abbreviation

### Datasource (extends Service)

**Kept:** versionControl, datasourceClassification, thematic, jurisdiction (now shared with Service)
**New:** researchProductTypes (plain string array, no vocabulary lookup per D9), own PID prefix
**Removed:** submissionPolicyUrl, preservationPolicyUrl, persistentIdentitySystems (fully dropped per D9 — no restructure), researchEntityTypes, researchProductLicensings, researchProductMetadataLicensing, researchProductAccessPolicies, researchProductMetadataAccessPolicies
**Dead but still in response (ignore in importer):** `harvestable` — key still emitted as `null` on 2/2 DS records on 2026-04-17. Column dropped per Slice D, importer does not read it.
**Note:** DS is now a Service type. `"type"` field returns `"DataSource"` (capital S) — mapped to Rails STI `Datasource` per D11. The `type` discriminator is universal across the Service-hierarchy endpoints: Service returns `"Service"`, DeployableApplication returns `"DeployableApplication"`, Adapter returns `"Adapter"`, etc. Existing DS migration deferred per-owner (D4).

### New Entity Types

- **Adapter** - linkedResource, documentation, repository, package, programmingLanguage, license, version, changeLog, lastUpdate, creators, tagline, logo, sqa, urls, alternativePIDs (all 13 verified in live /public/adapter/all response on 2026-04-17)
- **TrainingResource** - eoscRelatedServices, keywords, accessRights, versionDate, targetGroups, learningResourceTypes, learningOutcomes, expertiseLevel, contentResourceTypes, duration, languages, scientificDomains, creators, **qualifications** (not previously listed — returned by live API, consumed from `TR_QUALIFICATION` vocab). **`license` NOT returned by live API today (2026-04-17)** — schema may allow it but 1/1 integration records omit it; Slice I parser must tolerate missing key
- **InteroperabilityGuideline** - **resourceTypeInfo** (singular — README previously had typo `resourceTypesInfo`), relatedStandards, creators. **`license` NOT returned by live API today (2026-04-17)** on the 3 integration records; Slice H parser already tolerates missing key

### Vocabularies Removed (18 types)

AreaOfActivity, SocietalGrandChallenge, StructureType, EsfriDomain, EsfriType, MerilScientificDomain, Network, ProviderLifeCycleStatus, LifeCycleStatus, AccessMode, FundingBody, FundingProgram, MarketplaceLocation, ServiceCategory, EntityType, EntityTypeScheme, ResearchProductAccessPolicy, ResearchProductMetadataAccessPolicy

**Note:** `TARGET_USER` is KEPT per D8 (used by TrainingResource `targetGroups` in Slice I). `DS_RESEARCH_ENTITY_TYPE` and `DS_PERSISTENT_IDENTITY_SCHEME` are DROPPED per D9 — V6 stores `researchProductTypes` as plain string array.

### New Vocabulary Types in V6 API (not in V5)

All 16 verified served 2026-04-16 (item counts): `ADAPTER_PROGRAMMING_LANGUAGE` (50), `SPDX_LICENSE` (727 — watch fixture seeding), `SQA_BADGE` (3), `CREDIT` (14), `TR_ACCESS_RIGHT` (4), `TR_CONTENT_RESOURCE_TYPE` (12), `TR_DCMI_TYPE` (11), `TR_EXPERTISE_LEVEL` (4), `TR_QUALIFICATION` (3), `LANGUAGE` (185), `ORDER_TYPE` (4), `REGION` (5), `RESOURCE_STATE` (3), `CT_COMPATIBILITY` (4), `CT_PROTOCOL` (1), `TEMPLATE_STATE` (4).

Per D12: import only vocabularies consumed by entities actually implemented. `ORDER_TYPE` already handled as plain string; `LANGUAGE`/`REGION` NOT imported (V6 Service drops geo/language availability). Adapter + TR vocabularies gated on Slice I (D24 default: deferred).
