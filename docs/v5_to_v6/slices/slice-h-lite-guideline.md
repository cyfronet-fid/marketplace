# Slice H Lite: Guideline V6 Compatibility (0.25d)

**Status:** Implemented and validated (2026-04-29)  
**Validation basis:** API-verified against integration on 2026-04-30; repo-verified current implementation still uses V5 `title`.

Keep the existing lightweight Marketplace Guideline model. The full Slice H schema expansion is not required for the V6 import cutover today: a full authenticated `rails import:all` completed against integration with the existing service-guideline connection flow, and `/public/resourceInteroperabilityRecord/all` returns populated link data.

The actual V6 compatibility gap is narrower: live V6 `InteroperabilityGuideline` records use `name`, while current Marketplace code reads and stores `title`. Because `guidelines.title` is nullable, the current import can pass without raising while storing blank labels.

## Findings

- `GET /public/interoperabilityRecord/all?quantity=3&from=0` returns records with `id`, `name`, `description`, `type`, `publishingDate`, `nodePID`, `resourceOwner`, `publicContacts`, `creators`, `resourceTypeInfo`, and `relatedStandards`.
- The endpoint does **not** return `title` on integration as of 2026-04-30.
- `GET /public/resourceInteroperabilityRecord/all?quantity=10000&from=0` returns populated service links (`total: 30` on 2026-04-30), with `resourceId`, `interoperabilityRecordIds`, and `nodePID`.
- Running `rails import:all` with `MP_IMPORT_TOKEN` completed through guideline connection import. "Service source ... not found" lines indicate local dataset/source mismatches, not a V6 endpoint or parser failure.
- Slice G already routes JMS/AMS `interoperability_record.*` messages to existing Guideline jobs. Those jobs still parse `title`, so event sync needs the same `name` compatibility fix as batch import.

## Implementation Contract

- Do **not** add a new `interoperability_guidelines` model/table.
- Do **not** widen `guidelines` for rich V6 metadata in this migration unless a concrete Marketplace UI/API/ESS consumer is identified.
- Keep the existing `guidelines.title` column for now to minimize blast radius in views, serializers, filters, and helper code.
- Map V6 `name` into the existing `title` attribute.
- Keep accepting legacy `title` as a fallback for compatibility with old messages or fixtures.
- Keep `service_guidelines` as the service-link join table.

## Implementation Steps

1. Update `Import::Guidelines#import_guidelines`:

   - Read `title = external_data["name"].presence || external_data["title"]`.
   - Log using the parsed title/name value.
   - Keep the endpoint suffix as `public/interoperabilityRecord`; `Importers::Request` already builds the correct `/all?quantity=10000&from=0` URL.

2. Update `Guideline::PcCreateOrUpdate`:

   - Use `guideline_data["name"].presence || guideline_data["title"]`.
   - Keep current active/suspended behavior.
   - Add/update specs for V6 payloads with only `name`.

3. Keep `Import::Guidelines#connect_guidelines` mostly unchanged:
   - Continue reading `resourceId` and `interoperabilityRecordIds`.
   - Fix the nested-array lookup if touched:

```ruby
guidelines = Guideline.where(eid: guideline_eids)
```

4. Add focused tests:
   - Batch importer persists `guidelines.title` from V6 `name`.
   - Batch importer still accepts legacy `title`.
   - `Guideline::PcCreateOrUpdate` creates/updates from V6 `name`.
   - Service-guideline connection import links existing services to existing guidelines via `service_guidelines`.

## Validation

```bash
bundle exec rspec spec/lib/import/guidelines_spec.rb \
                  spec/services/guideline/pc_create_or_update_spec.rb
```

```bash
DRY_RUN=true bundle exec rake import:guidelines
```

Expected dry-run signs:

- Logs guideline names, not blank titles.
- No `NoMethodError` on `title`.
- Connection import reaches `Connecting guidelines to ...` lines.
- Missing local service sources are logged and skipped.

For a real authenticated check:

```bash
MP_IMPORT_TOKEN=<token> bundle exec rake import:guidelines
```

Expected persisted result:

```ruby
Guideline.where(title: [nil, ""]).count == 0
```

for the records returned by the V6 interoperability endpoint.

## Deferred From Full Slice H

These are intentionally not part of H Lite:

- Rename `guidelines.title` to `guidelines.name`.
- Add `GuidelineSource`.
- Add `guideline_alternative_identifiers`.
- Store `description`, `publishing_date`, `resource_type`, `resourceTypeInfo`, `license`, `creators`, `nodePID`, `resourceOwner`, `publicContacts`, `relatedStandards`, or `urls`.
- Add new Guideline management UI.
- Change ESS output shape for guidelines.

Revisit the full schema expansion only if Marketplace needs to display, search, export, or propagate rich interoperability record metadata.

## Definition of Done

- V6 guideline batch import stores visible labels from `name`.
- V6 guideline JMS/AMS events store visible labels from `name`.
- Legacy `title` payloads still work.
- Service-guideline connection import still works with `/public/resourceInteroperabilityRecord`.
- No database migration is required for this slice.
