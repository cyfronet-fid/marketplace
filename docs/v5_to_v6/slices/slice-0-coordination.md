# Slice 0: Coordination (0.5d)

## Goal

Resolve every decision below BEFORE any code is written. Each decision has a "Blocks" line showing which later slices cannot start (or will hit a TBD) until it is answered. Update README.md open-questions list once the decision is recorded here.

## Decisions (each must produce a single chosen answer, not a TBD)

### D1. Catalogue schema

Ask Athena which Catalogue fields persist in V6 and which are removed.

- **Blocks:** Slice F (entire slice).
- **Default if unanswered by start of Slice F:** defer Slice F to a follow-up PR and mark it out of scope for this migration.
- **Verified (2026-04-17, corrects 2026-04-16 error):** the earlier "endpoint does not exist" claim was a wrong-path artefact. Catalogue is the only entity in V6 with no `/public/` variant — the swagger exposes only `/catalogue/all` (unauthenticated, 200) and `/catalogue/bundle/all` (admin, 403). The previous `public/catalogue/all` 404 was the server refusing an endpoint that never existed, not a signal about V6 readiness. The real evidence for deferral is the **response body shape**: `GET /catalogue/all` on integration returns 5 records still in V5 form — every "to be removed" field is still present (`inclusionCriteria`, `validationProcess`, `endOfLife`, `scope`, `location`, `multimedia`, `scientificDomains`, `tags`, `participatingCountries`, `affiliations`, `networks`, `mainContact`, `users`), `publicContacts` is still array-of-objects (not email array), and the V6 additions (`nodePID`, `alternativePIDs`) are absent. Athena has not shipped V6 Catalogue schema yet. Deferral stands, now backed by the right evidence.

### D2. `mainContact` / `users` API removal date

Confirm when PC stops returning these transitional fields.

- **Blocks:** nothing hard, but the answer decides whether importers can ignore them (current direction) or must still read them for a fallback period.
- **Default:** ignore them in all new importers (Slices B, C, D, E, F, H). If Athena confirms removal is > 3 months away, keep dead-letter logging if they arrive non-empty.
- **Verified (2026-04-16, integration):** both fields are STILL returned. `mainContact` = `{email, firstName, lastName}` object on 3/3 sampled orgs and 3/3 services. `users` = array of `{id, email, name, surname}` on 3/3 orgs. Removal has not happened; ignoring them is safe today but we will not notice the removal date unless Athena tells us.

### D3. Archive vs. drop removed Provider/Service data

Decide whether data in columns being dropped (`certifications`, `affiliations`, `national_roadmaps`, contacts, etc.) is archived to a JSON blob or discarded.

- **Blocks:** Slice B (B2), Slice C (C2), Slice F (F1).
- **Default:** drop. Add a single `rake db:v5_archive` task at the top of Slice B that dumps pre-migration rows to `tmp/v5_archive_YYYYMMDD.json` if the operator sets `ARCHIVE=true`.

### D4. Datasource migration plan

Existing Datasource rows keep V5 `pid` or get new V6-style DS prefix?

- **Blocks:** Slice D (D1, D2).
- **Default:** no renames for existing DS rows. New DS records imported under V6 will carry whatever `id` the PC returns. Any `"type": "DataSource"` (capital S) is mapped to Rails STI `Datasource` in Slice D.

### D5. AMS topic names for new entity types

Confirm `mp-adapter-{create,update,delete}` and `mp-training_resource-{create,update,delete}` names with Athena.

- **Blocks:** Slice G (G3), Slice I (I1, I2).
- **Default:** the names above. If Slice I is deferred, G3 does not add them.

### D6. Tag storage

Keep `acts_as_taggable` (Service) or switch to a `tags` string array column?

- **Blocks:** Slice B (B3 removes tagging for Provider), Slice C (C3 depends on this), Slice F (F2), Slice J (J3 cleanup of taggings table).
- **Default:** keep `acts_as_taggable` on Service; remove it from Provider and Catalogue. No new column. `taggings` rows for `taggable_type IN ('Provider','Catalogue')` are deleted in B2 and F1.

### D7. `legalStatus` / `hostingLegalEntity` storage

API returns vocabulary EIDs as strings (e.g. `"provider_legal_status-european_research_infrastructure_consortium"`). Keep `Vocabulary::LegalStatus`/`Vocabulary::HostingLegalEntity` lookup, or store the raw EID string on the Provider row?

- **Blocks:** Slice A (A1 keep list, A3 keep list, A4 keep list), Slice B (B2 columns-to-keep, B3 associations, B5 importer, B9 form partials).
- **Default:** keep the vocabulary models and lookup. Rationale: zero UI change, no data migration, lookup still works because the V6 string IS the EID we already store. Revisit after V6 ships if the vocab model no longer earns its keep.
- **Verified (2026-04-16, integration):** `legalStatus` returns singular string EID, e.g. `"provider_legal_status-foundation"` (2/3 sampled orgs non-null, matches existing `Vocabulary::LegalStatus.eid` keys). `hostingLegalEntity` key is present but null/empty on 0/3 sampled orgs — shape unverified against real data, but matches the V6 schema; lookup will work whenever producers populate it.
- **Re-verified (2026-04-17, full population):** `legalStatus` singular EID across 20/20 integration orgs. `hostingLegalEntity` now populated on **5/20 orgs** (was 0/3 yesterday) — real production data has arrived. Lookup default confirmed working against live data.

### D8. `TARGET_USER` vocabulary

V6 API still serves 18 items. Needed for TrainingResource `targetGroups` in Slice I.

- **Blocks:** Slice A (A1 keep list, A4 keep list).
- **Default:** KEEP `TargetUser` model, `TARGET_USER` in `ACCEPTED_VOCABULARIES`, and `target_user` in `VOCABULARY_TYPES`. Remove the `service_target_users` join and `has_many :target_users` on Service (Slice C3) because Service no longer references it. The model + vocabulary import stays alive for Slice I (TrainingResource). If Slice I is deferred permanently, delete in Slice J cleanup.
- **Verified (2026-04-16, integration):** `vocabulary/byType` returns `TARGET_USER` with 18 items. Dev and integration agree exactly. The 18-item claim is confirmed fact.

### D9. `DS_RESEARCH_ENTITY_TYPE` / `DS_PERSISTENT_IDENTITY_SCHEME` vocabularies

V6 API still serves them (9 and 8 items). Used by Datasource `researchProductTypes` / PID system fields.

- **Blocks:** Slice A (A1 delete list, A4 keep list — currently contradicts itself), Slice D (D2).
- **Default:** DROP both. Rationale: V6 Datasource `researchProductTypes` is a plain string array (Slice D), not a vocabulary lookup. The PID system struct is being reshaped in D2 and no longer uses `Vocabulary::EntityType`/`EntityTypeScheme`. Remove the models (A1), remove the two entries from `ACCEPTED_VOCABULARIES` (A4), remove `entity_type` / `entity_type_scheme` / `product_access_policy` from `VOCABULARY_TYPES` (A3).
- **Verified (2026-04-16, integration):** `DS_RESEARCH_ENTITY_TYPE` (9 items) and `DS_PERSISTENT_IDENTITY_SCHEME` (8 items) are still served by the vocab endpoint. Confirmed `researchProductTypes` on a live Datasource returns e.g. `["ds_research_entity_type-research_data"]` — a plain string array, matching the drop-the-vocab-lookup direction. Default stands.

### D10. `SUPERCATEGORY` vocabulary

Absent from V6 vocabulary API — only `CATEGORY` and `SUBCATEGORY` remain.

- **Blocks:** Slice A (A4 keep list).
- **Default:** REMOVE `SUPERCATEGORY` from `ACCEPTED_VOCABULARIES`. Keep only `CATEGORY` and `SUBCATEGORY`.
- **Verified (2026-04-16, integration):** `vocabulary/byType` returns 31 vocab keys; `SUPERCATEGORY` is ABSENT. `CATEGORY` (20 items) and `SUBCATEGORY` (179 items) are present. Confirmed.

### D11. Datasource `"type": "DataSource"` (capital S) mapping

API returns capital-S. Rails STI class is `Datasource`.

- **Blocks:** Slice D (D3).
- **Default:** map in `Importers::Datasource` with an explicit `case`: `"DataSource"` → STI discriminator `"Datasource"`. No schema change.
- **Verified (2026-04-16, integration):** sampled Datasource records return `"type": "DataSource"` (capital S). Confirmed — importer must downcase/remap.
- **Re-verified (2026-04-17, integration):** `type` is a universal discriminator across every entity type sharing the Service hierarchy, not just Datasource. Observed values across full populations: Service `"Service"` (66/66), Datasource `"DataSource"` (2/2), DeployableApplication `"DeployableApplication"` (8/8), Adapter `"Adapter"` (3/3), TrainingResource `"TrainingResource"` (1/1), InteroperabilityRecord `"InteroperabilityGuidelines"` (3/3). Only DS's capital-S mid-word needs special-casing. Importers for the other types should still record the returned `type` string for auditing — it is the canonical EOSC resource class label.

### D12. 16 new V6 vocabulary types

`ADAPTER_PROGRAMMING_LANGUAGE`, `SPDX_LICENSE`, `SQA_BADGE`, `CREDIT`, `TR_ACCESS_RIGHT`, `TR_CONTENT_RESOURCE_TYPE`, `TR_DCMI_TYPE`, `TR_EXPERTISE_LEVEL`, `TR_QUALIFICATION`, `LANGUAGE`, `ORDER_TYPE`, `REGION`, `RESOURCE_STATE`, `CT_COMPATIBILITY`, `CT_PROTOCOL`, `TEMPLATE_STATE`.

- **Blocks:** Slice I (I1, I2). `LANGUAGE`/`ORDER_TYPE`/`REGION` may affect Slice C.
- **Default:** in this migration, add ONLY the ones consumed by entities we actually implement. If Slice I is in scope → add the Adapter+TR vocabularies. `ORDER_TYPE` is already handled as a plain string (not a vocab) — leave as-is. `LANGUAGE` and `REGION` are not needed by simplified V6 Service (geographical/language availability removed). Do not import them.
- **Verified (2026-04-16, integration):** all 16 listed vocab types are served. Item counts: `ADAPTER_PROGRAMMING_LANGUAGE`=50, `SPDX_LICENSE`=727, `SQA_BADGE`=3, `CREDIT`=14, `TR_ACCESS_RIGHT`=4, `TR_CONTENT_RESOURCE_TYPE`=12, `TR_DCMI_TYPE`=11, `TR_EXPERTISE_LEVEL`=4, `TR_QUALIFICATION`=3, `LANGUAGE`=185, `ORDER_TYPE`=4, `REGION`=5, `RESOURCE_STATE`=3, `CT_COMPATIBILITY`=4, `CT_PROTOCOL`=1, `TEMPLATE_STATE`=4. `SPDX_LICENSE` at 727 items is worth a note for fixture-seeding (Slice A5 should not materialize all of them).

### D13. `accessTypes` shape

V6 API is **inconsistent**: `Service` returns an array of strings, `Datasource` returns a singular string. `Array()` wrapping handles both.

- **Blocks:** Slice C (C5), Slice D (D2).
- **Default:** write explicit `Array(@data["accessTypes"])` in every importer that reads this field. Comment must say "API is inconsistent — array on Service, string on Datasource — Array() handles both." Do not switch the column type.
- **Verified (2026-04-16, integration):** Service sample returns `["access_type-physical", "access_type-remote"]` (array of 2). Datasource sample returns `"access_type-remote"` (bare string). Previous Slice 0 claim that "V6 API returns a singular string" was wrong for Service — confirmed by sampling.
- **Re-verified (2026-04-17, full population):** divergence holds across all records. Service: 66/66 records return `accessTypes` as `array` or `null` (no bare strings). Datasource: 2/2 records return `accessTypes` as `string` (no arrays). `Array()` wrap still the correct default.

### D14. `alternativePIDs` shape and storage

V6 schema replaces `alternativeIdentifiers` (`{type, value}`) with `alternativePIDs` (`{pid, pidSchema}`).

- **Blocks:** Slice B (B2, B5), Slice C (C2, C5), Slice E (E1, E3), Slice H (H1, H3).
- **Default:** reuse the existing `alternative_identifiers` join table. Map `{pid, pidSchema}` → `AlternativeIdentifier.new(identifier_type: pidSchema, value: pid)`. No new column, no migration. Every entity's importer handles this via the existing `map_alternative_identifier` helper (which stays in `Importable`).
- **Verified (2026-04-16, integration):** live shape confirmed from Datasource sample: `[{"pid": "fairsharing_::7260", "pidSchema": "openaire"}]`. The old `alternativeIdentifiers` key is NOT present on any sampled entity. `alternativePIDs` key is present on Datasource (2/2 non-empty) and Adapter (2/3 present, all empty); absent or empty on Organisation / Service / DeployableApplication / TrainingResource samples. Importer helper must handle absent-key and empty-array cases, which `map_alternative_identifier` already does.
- **Re-verified (2026-04-17, full population):** Organisation — 17/20 omit the key entirely, 3/20 include it as `null`, **0/20 populated**. Service — 0/66 have the key. Datasource — 2/2 populated with `[{pid, pidSchema}]`. Helper tolerates all three serialisation variants (missing / null / array) — no change needed. Only DS currently exercises the populated path.

### D15. `urls` (string array) column scope

V6 adds a top-level `urls` array to Service, DeployableApplication, Adapter, TrainingResource.

- **Blocks:** Slice C (C2, C5), Slice E (E1, E3), Slice I.
- **Default:** add a `urls string[] default []` column to `services` (Slice C2) and `deployable_services` (Slice E1). Map directly — no helper needed. Slice I tables include it from day one.
- **Verified (2026-04-16, integration):** `urls` key is ABSENT from all sampled Service (0/3), DeployableApplication (0/3), TrainingResource (0/1), Organisation (0/3), and Datasource (0/2) records. Present on Adapter (2/3) but empty on both. Conclusion: V6 producers omit the field when empty — importer must treat missing key the same as empty array (`Array(@data["urls"])`). Migration column + importer logic are safe to write; cannot be exercised against live data until producers populate it.
- **Re-verified (2026-04-17, full population):** Service 0/66, Organisation 0/20, DeployableApplication 0/8, TrainingResource 0/1, Datasource 0/2, InteroperabilityRecord 0/3. Adapter 3/3 have the key but all empty. No live `urls` data anywhere. Column + importer still safe to ship; end-to-end test against live data must wait for producer adoption.

### D16. `nodePID` lookup semantics

V5 sent `node` (string array of EIDs). V6 sends `nodePID` (singular string, potentially a PID not an EID).

- **Blocks:** Slice B (B5), Slice C (C5), Slice E (E3), Slice H (H3).
- **Default:** treat `nodePID` as an EID for now (matches our existing `Vocabulary::Node.eid` keys). Wrap with `Array()` before passing to `map_nodes`. If a future import returns 0 matches, the fix is to add a `pid` field to `Vocabulary::Node` — not in scope here.
- **Verified (2026-04-16, integration):** `nodePID` returned as a singular string, EID-form, on every entity type sampled. Examples: Organisation `"node-egi"`, Service `"node-instruct_eric"`, Datasource `"node-enes"`, Adapter `"node-sandbox"`, DeployableApplication `"node-nfdi"`, TrainingResource `"node-sandbox"`. The old array-of-EIDs `node` field is NOT returned. Default confirmed: `Array(@data["nodePID"])` and look up by EID.

### D17. `publicContacts` shape during transition

V6 says email array. README line 42 warns `publicContacts` is in the response alongside `mainContact`/`users`. Shape may still be array-of-objects.

- **Blocks:** Slice B (B5), Slice C (C5), Slice E (E3), Slice F (F3), Slice H (H3).
- **Default:** write importers defensively: `emails = Array(@data["publicContacts"]).map { |c| c.is_a?(Hash) ? c["email"] : c }.compact.uniq`. Wrap in a private helper `extract_public_contact_emails` used by every importer that needs it (lives in `Importable`).
- **Verified (2026-04-16, integration):** `publicContacts` is an **array of plain strings** on every sampled entity (`["default@example.com"]` on all 14 non-null samples across 6 entity types). No array-of-objects form observed. The helper still works; the `is_a?(Hash)` branch is currently defensive dead code. Leave it in — it's cheap insurance against the schema drifting back.
- **Re-verified (2026-04-17, full population):** plain-string arrays across 20/20 orgs, 66/66 services, 2/2 DS, 8/8 DAs, 3/3 adapters, 1/1 TR, 3/3 IRs. Zero array-of-object responses anywhere. Defensive `is_a?(Hash)` branch stays.

### D18. `Importers::Request` URL construction for V6

`Importers::Request#all` appends `/all?quantity=10000&from=0` to the passed suffix. V5 suffix `public/provider/bundle` produces `public/provider/bundle/all?...`. V6 new endpoints are already documented as `public/organisation/all` — passing that verbatim would produce `public/organisation/all/all?...`.

- **Blocks:** Slice B (B6), Slice C (C6), Slice D (DS import), Slice E (E4), Slice H (H5).
- **Default:** pass the suffix WITHOUT `/all` (e.g. `public/organisation`) and let `Importers::Request#all` append it. Update every orchestrator in Slices B–H accordingly. Confirm by `curl`ing `https://dev.providers.sandbox.eosc-beyond.eu/api/public/organisation/all?quantity=10000&from=0` before coding.

### D19. `data_administrators` retention

V6 drops `users` from Provider/Catalogue API. We currently derive `data_administrators` from it.

- **Blocks:** Slice B (B3, B5, B9), Slice F (F2, F3).
- **Default:** KEEP the `data_administrators` association for internal auth (`owned_by?` checks reference it). STOP populating it from the importer (Slices B5, F3). Users must be added via the backoffice. Document in Slice B9's managers partial.

### D20. PC cutover style — hard cut vs. dual-emit

Determines whether AMS subscribes to V6 topic names only, or both V5 + V6 during a transition window. Athena controls the publisher; we only react.

- **Owner to ask:** Athena (PC team).
- **Blocks:** Slice G (G3 `ams_subscriber.yml`, G4 `MP_STOMP_DESTINATION`, G1/G2 `INBOUND_TOPIC_ALIASES` retirement). If dual-emit is confirmed, G3 lists 12 topic names (6 V5 + 6 V6) and Slice J cannot remove the aliases until the dual-emit window closes.
- **Default (if unanswered by Slice G start):** assume HARD CUT. Subscribe to V6 names only. Keep `INBOUND_TOPIC_ALIASES` + dual-key body parse in the code as a safety net (those are free — no subscription required). If PC is actually dual-emitting, MP will simply miss V5 topic messages for the transition window — acceptable because the batch importer catches up on the next cron tick.

### D21. ESS consumer contract — `dedicated_for` / `unified_categories` removal

Slice C deletes these two Service attributes. ESS (eosc-search-service) historically consumed them. If ESS still depends on them, Slice C ships a breaking change.

- **Owner to ask:** ESS team.
- **Blocks:** Slice C (C8 `Ess::ServiceSerializer`, C9 `search_data`).
- **Default (if unanswered by Slice C start):** DROP the fields in the Rails model/migration as planned, BUT temporarily leave them in `Ess::ServiceSerializer` as empty-value attributes (`dedicated_for: [], unified_categories: []`) so the ESS contract doesn't break. Remove the serializer stubs in a follow-up PR once ESS confirms.

### D22. Federation consumer audit — `federation/services_controller.rb`

Unknown who consumes `/federation/services.json`. If external consumers still read removed attributes, the response shape change breaks them silently.

- **Owner to ask:** EOSC operations / whoever owns consumer contracts. Grep the monitoring for recent hits is a proxy.
- **Blocks:** Slice J (J3 dead-code sweep — the line "Coordinate with any federation consumers before removing").
- **Default (if unanswered by Slice J start):** KEEP the federation serializer as-is in this migration. Emit removed fields as `nil` / `[]` (not removed from the JSON response). Open a follow-up issue to remove them after one deprecation cycle. This is the conservative path — federation consumer breakage is silent and expensive to discover.

### D23. Ops — `MP_STOMP_DESTINATION` production value

The STOMP subscriber reads a single destination pattern from env. We don't know the current prod value, and we don't know if the STOMP client accepts comma-separated wildcards.

- **Owner to ask:** Ops / infra team.
- **Blocks:** Slice G (G4 env update).
- **Default (if unanswered by Slice G start):** the G4 documentation is correct, but the ENV value change is OUT OF SCOPE for this PR — file a devops ticket linked from Slice G4 and leave the current single-destination subscription alive. A second STOMP subscription ticket can follow after the code change lands. Confirm with ops whether the current value is a wildcard (`*.provider.*`) — if yes, the rename to `*.organisation.*` can ship atomically with the code; if not, multiple subscriptions are needed and that's a separate ops task.

### D24. Product — Slice I scope (Adapter + TrainingResource in this PR or follow-up)

Slice I is 4 days of work and can ship as a separate PR. If deferred, Slice J must additionally delete `TargetUser` + remove 10 deferred vocab types.

- **Owner to ask:** Product / engineering lead.
- **Blocks:** Slice I (entire slice), Slice A (A1 `TargetUser` retention), Slice J (J3 `TargetUser` conditional deletion, J4 deploy checklist lines for adapter/TR topics).
- **Default (if unanswered by Slice I start):** DEFER to follow-up PR. Migration PR ships A–H + J only. `TargetUser` + its 10 reserved vocab types stay in place (per D8/D12 keep lists) so the follow-up PR is a pure additive change with no Slice J cleanup rework. Downside: 10 unused vocabs imported into production until Slice I ships; acceptable cost.

## Empirical verification summary (2026-04-16)

Run against `https://integration.providers.sandbox.eosc-beyond.eu/api` (cross-checked with dev where shapes differ).

| D#      | Decision                               | Status | Evidence                                                                                                                                                                   |
| ------- | -------------------------------------- | ------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| D1      | Catalogue endpoint                     | ⚠     | `/catalogue/all` returns 200 on both envs with V5-shaped payload; 404 on `/public/catalogue/all` was a wrong-path artefact. Deferral stands — server still emits V5 schema |
| D2      | `mainContact`/`users` removal          | ⚠     | Still returned today — removal date unknown                                                                                                                                |
| D7      | `legalStatus` shape                    | ✓      | Singular EID string (`provider_legal_status-foundation`)                                                                                                                   |
| D8      | `TARGET_USER` item count               | ✓      | 18 items                                                                                                                                                                   |
| D9      | DS vocabs present                      | ✓      | `DS_RESEARCH_ENTITY_TYPE` 9, `DS_PERSISTENT_IDENTITY_SCHEME` 8; drop decision still good                                                                                   |
| D10     | `SUPERCATEGORY` absent                 | ✓      | Not in `vocabulary/byType` response                                                                                                                                        |
| D11     | `"DataSource"` capital-S               | ✓      | Literal string `"DataSource"` on Datasource records                                                                                                                        |
| D12     | 16 new vocab types present             | ✓      | All 16 present; `SPDX_LICENSE` at 727 items is the outlier                                                                                                                 |
| D13     | `accessTypes` shape                    | ⚠     | Service returns array; Datasource returns string. Decision rewritten                                                                                                       |
| D14     | `alternativePIDs` shape                | ✓      | `[{pid, pidSchema}]` confirmed on Datasource; absent/empty elsewhere                                                                                                       |
| D15     | `urls` field                           | ⚠     | Omitted when empty on all sampled entities — importer must tolerate missing key                                                                                            |
| D16     | `nodePID` singular EID                 | ✓      | Singular `node-*` string on 6 entity types                                                                                                                                 |
| D17     | `publicContacts` shape                 | ✓      | Array of plain strings, not array of objects                                                                                                                               |
| D18     | Request URL suffix                     | ✓      | Already curl-verified during slice writeup                                                                                                                                 |
| D3–D6   | Archive / DS rename / topics / tagging | —      | Require stakeholder input — not API-derivable                                                                                                                              |
| D19–D24 | Internal / ops / ESS / product         | —      | Require stakeholder input — not API-derivable                                                                                                                              |

Legend: ✓ default stands and is backed by evidence; ⚠ default still safe but the premise in the original decision text was wrong or incomplete — updated inline. `—` cannot be verified from the API.

## Re-verification delta (2026-04-17)

Ran against the full integration population (no sampling). Endpoint counts match README's 2026-04-17 table exactly. Per-decision deltas:

| D#  | What changed vs. 2026-04-16                                                                                                                                                                                                                                  |
| --- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| D1  | Catalogue keys on `/catalogue/all` still V5-shaped (24 keys including `endOfLife`, `inclusionCriteria`, `users`) — deferral stands                                                                                                                           |
| D7  | `hostingLegalEntity` populated on **5/20 orgs** (was 0/3) — real data has arrived, lookup default works against live                                                                                                                                         |
| D11 | `type` discriminator generalised to all Service-hierarchy entities (Service / DA / Adapter / TR / IR) — not just DS                                                                                                                                          |
| D13 | Divergence verified across full pop: Service 66/66 array-or-null, DS 2/2 string                                                                                                                                                                              |
| D14 | Organisation: 17/20 omit key, 3/20 null, **0/20 populated** (no live Org has non-null altPIDs yet)                                                                                                                                                           |
| D15 | `urls` populated on 0 records across all 7 entity types in full-population sweep                                                                                                                                                                             |
| D17 | Plain-string arrays across 103 non-null samples; `is_a?(Hash)` branch dead code                                                                                                                                                                              |
| —   | **Slice I field lists corrected:** TrainingResource has `qualifications` (not in old list); `license` NOT returned on TR or IR today; InteroperabilityRecord field is `resourceTypeInfo` singular, not `resourceTypesInfo`. See Slice H / Slice I for detail |
| —   | **Datasource `harvestable` field still returned as `null`** (Slice D notes it is dropped — clarified: importer ignores, column removed, but response payload still contains the dead key)                                                                    |

## Swagger caveat

`docs/v5_to_v6/swagger/{dev,integration,prod}.json` (version `5.4.1-SNAPSHOT`) is a useful endpoint inventory but **cannot verify field-level shapes**. Every payload bundle in `components.schemas` collapses to `{type: object, additionalProperties: {}}` — the Spring-generated swagger never walked the DTO classes. Use swagger for path discovery, HTTP method / status inventory, and request-parameter docs only. Every field-shape claim in this document was produced by `curl` against a live environment.

**Commands for reproducibility:**

```bash
curl -s "https://integration.providers.sandbox.eosc-beyond.eu/api/vocabulary/byType" | jq 'keys'
curl -s "https://integration.providers.sandbox.eosc-beyond.eu/api/public/organisation/all?quantity=3&from=0" | jq '.results[0]'
curl -s "https://integration.providers.sandbox.eosc-beyond.eu/api/public/service/all?quantity=3&from=0"      | jq '.results[0]'
curl -s "https://integration.providers.sandbox.eosc-beyond.eu/api/public/datasource/all?quantity=3&from=0"   | jq '.results[0]'
curl -s "https://integration.providers.sandbox.eosc-beyond.eu/api/public/adapter/all?quantity=3&from=0"      | jq '.results[0]'
curl -s "https://integration.providers.sandbox.eosc-beyond.eu/api/public/deployableApplication/all?quantity=3&from=0" | jq '.results[0]'
curl -s "https://integration.providers.sandbox.eosc-beyond.eu/api/public/trainingResource/all?quantity=3&from=0"      | jq '.results[0]'
curl -s "https://integration.providers.sandbox.eosc-beyond.eu/api/catalogue/all?quantity=3&from=0"          | jq '.results[0] | keys'
curl -s -o /dev/null -w "%{http_code}\n" "https://integration.providers.sandbox.eosc-beyond.eu/api/public/catalogue/all?quantity=10&from=0"   # 404 — endpoint does not exist
curl -s -o /dev/null -w "%{http_code}\n" "https://integration.providers.sandbox.eosc-beyond.eu/api/catalogue/bundle/all?quantity=10&from=0"   # 403 — admin-only
```

## Validate

All `[ ]` checkboxes in README.md either checked or linked to a "Default:" above. No slice file contains the literal string "TBD" after Slice 0 completes.

```bash
grep -n "TBD" docs/v5_to_v6/slices/*.md
# Should return empty
```

**Commit Slice 0 as the first PR of the migration.** Every later slice references decisions D1–D24 by number.
