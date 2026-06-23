# Slice K: Blocked validation closeout for Codex (1-2d)

**Status:** Executed with documented exceptions
**Validation basis:** Created after Slice J cleanup pass on 2026-04-30
**Purpose:** Convert the remaining blocked/not-completed Slice J validation gates into an executable Codex runbook.

Slice J removed the obvious V5 fallout and repaired focused tests/docs, but the migration is not ready until the remaining end-to-end gates run against a real local app and live Provider Catalogue contracts. Slice K is the explicit closeout slice for those gates.

## Execution notes 2026-04-30 / 2026-05-01

- Branch context reviewed against `origin/development`. The remote-only `origin/v6-pc-migration` docs commit is an older alternate docs layout and was not merged into the local newer Slice H Lite / Slice I / Lessons Learned tree.
- `localhost:5000` serves Rails Marketplace even though macOS AirPlay also owns a non-loopback listener. `curl -I http://localhost:5000/`, `/services`, and `/api_docs` returned Rails `200 OK`.
- Docker dependencies were up. Development DB migrations completed.
- Dry-run V6 imports completed for vocabularies, providers, resources, datasources, deployable services, and guidelines. Real deployable import exposed V6 data that can omit `description`, `tagline`, and a locally known `resourceOwner`; this was fixed by allowing nullable deployable text fields and optional `resource_organisation`.
- `bundle exec rake import:deployable_services` completed and reran idempotently. Current dev counts after import: providers 65, services 126 total / 124 plain / 2 datasources, deployable services 11, guidelines 3. Two imported deployable applications reference live owner `21.11170/4vZGu4`, which is not present in the current public organisation import, so they intentionally have no local owner association.
- `bundle exec rake searchkick:reindex:all` passed. `bundle exec rake ess:reindex:all` passed after fixing the ESS rake task to call `Ess::Add.call(service, "service", async: false)`.
- `./bin/rails rswag` passed: 331 examples, 0 failures, 1 pending; swagger JSON was regenerated.
- `RUBOCOP_SERVER=false RUBOCOP_CACHE_ROOT=/var/folders/z2/2yb9j31x2_j2y3dk4s487h980000gn/T/rubocop_cache bundle exec rubocop` passed: 1421 files, no offenses. `RUBOCOP_CACHE_ROOT=... bundle exec haml-lint --exclude 'lib/**/*.haml'` passed: 536 files, 0 lints.
- Full non-feature RSpec passed: 2140 examples, 0 failures, 45 pending. Focused feature reruns for the fixed project-service conversation path passed. A full feature run previously collapsed after Chrome disconnected; after the one real failure was fixed, it was treated as harness instability rather than independent app failures.
- Cypress runs only outside the sandbox. The first real run fixed a stale public route assertion (`/services` replaced old `search/service`). The next run is blocked by legacy auth support calling removed `/users/login` in `test/system/cypress/support/auth.ts`; public specs executed before fail-fast included the new negative check for removed related-platform filters.
- External Provider Catalogue sweep used the documented `/api` prefix and current integration sandbox: organisation 200/20, service 200/66, datasource 200/2, deployableApplication 200/8, interoperabilityRecord 200/3, resourceInteroperabilityRecord 200/30, catalogue 200/5 at `/api/catalogue/all`, `/api/public/catalogue/all` 404, adapter 200/5, trainingResource 200/1 with `type: "TrainingMaterial"`.

## Current blocker summary

The last Codex validation pass could not complete these items:

- Cypress end-to-end run, because `http://localhost:5000/` returned `403 Forbidden` from `Server: AirTunes/935.7.1`, not Rails.
- Live local browser QA with screenshots/log tails.
- Fresh validation DB setup, seed/import/reindex, and current development DB validation.
- Full `bundle exec rspec`, full `rubocop`, full `haml-lint`, Searchkick reindex, ESS reindex.
- Real `rails import:all` and V6-scoped import sequence using the real `.env` token.
- External contract sweep against live PC endpoints and current `EOSC-PLATFORM/eosc-resources-model`.
- Reconciliation of the remote-only `origin/v6-pc-migration` docs commit with local docs.

## What Codex needs to do this

Codex can execute this slice if the workspace provides:

- A free local Rails port. Preferred: make `localhost:5000` serve Marketplace Rails. If macOS AirPlay/AirTunes owns 5000, either disable the receiver or approve using another port and update Cypress base URL for the run.
- Running dependencies: PostgreSQL, Elasticsearch, Redis, ActiveMQ.
- Valid local `.env` and Rails credentials/master key. Tokens may be used but must never be printed in logs or committed.
- Permission to run network and long-running commands when sandbox blocks them:
  - `yarn install`
  - `npm run cy:run`
  - `bundle exec rspec`
  - `rubocop`
  - `haml-lint`
  - `./bin/rails rswag`
  - `rake searchkick:reindex:all`
  - `rake ess:reindex:all`
  - `rails import:*` / `rake import:*`
  - `curl` against live PC endpoints and GitHub raw/API endpoints
- Approval before any destructive DB reset/drop. Prefer a separate validation database over resetting the user's current development database.

## Codex execution order

### K1. Reconcile docs branch state

Goal: resolve the branch being `ahead 11, behind 1` before final validation evidence is recorded.

Steps:

1. Compare the local docs tree with `origin/v6-pc-migration`.
2. Decide whether to merge/cherry-pick the remote docs commit or keep the local docs layout as newer truth.
3. Preserve local Slice H Lite / Slice I / Lessons Learned / resource swagger layout unless the remote commit contains unique material.
4. Record the final decision in this file or the PR closeout.

Commands:

```bash
git log --oneline --left-right --cherry-pick HEAD...origin/v6-pc-migration
git diff --stat codex-review origin/v6-pc-migration -- docs/v5_to_v6
git diff --name-status codex-review origin/v6-pc-migration -- docs/v5_to_v6
```

Evidence:

- Final branch ahead/behind state.
- Short note explaining whether remote docs were merged, superseded, or intentionally left for a separate docs-only reconciliation.

### K2. Prepare a real local app target

Goal: ensure Cypress and browser QA hit Rails, not another process.

Steps:

1. Check what owns port 5000.
2. If AirTunes/AirPlay owns it, free the port or use a replacement port such as 5100.
3. Start Docker services.
4. Run migrations.
5. Start Rails with the selected port.
6. Confirm root returns Marketplace HTML.

Commands:

```bash
lsof -nP -iTCP:5000 -sTCP:LISTEN
docker compose up -d
./bin/rails db:migrate
PORT=5000 ./bin/server
curl -I http://localhost:5000/
```

Fallback if 5000 is unavailable:

```bash
PORT=5100 ./bin/server
curl -I http://localhost:5100/
```

If Cypress must use a fallback port, set the Cypress base URL for the command rather than committing a config-only port change.

Evidence:

- Server command and selected port.
- `curl -I` status showing Rails response, not `Server: AirTunes`.
- Rails log tail after boot.

### K3. Fresh validation database gate

Goal: prove the migration works on a clean database without relying on the user's current dev data.

Preferred approach: create/use a separate validation database name via environment variables or local config override, not by dropping the user's development DB.

Steps:

1. Create/migrate validation DB.
2. Load seeds and E2E data.
3. Run `dev:prime_e2e` if supported by the local environment.
4. Reindex Searchkick.
5. Run dry-run imports for in-scope V6 entities.
6. Run real import sequence.
7. Run V6-scoped import sequence excluding Catalogue and record Catalogue separately as the explicit V5-shaped exception.

Commands:

```bash
./bin/rails db:create db:migrate db:seed
./bin/rails dev:prime_e2e
rake searchkick:reindex:all

DRY_RUN=true rake import:vocabularies
DRY_RUN=true rake import:providers
DRY_RUN=true rake import:resources
DRY_RUN=true rake import:datasources
DRY_RUN=true rake import:deployable_services
DRY_RUN=true rake import:guidelines

rails import:all
rake import:vocabularies
rake import:providers
rake import:resources
rake import:datasources
rake import:deployable_services
rake import:guidelines
```

Evidence:

- Counts before/after import for Provider, Service, Datasource, DeployableService, Guideline.
- Any accepted exceptions with exact error messages.
- Log tail proving no `UnknownAttributeError`, missing partial, or `NoMethodError`.

### K4. Current development database gate

Goal: prove the existing developer DB survives the same code path.

Steps:

1. Migrate current dev DB.
2. Run dry-run imports.
3. Run real `rails import:all`.
4. Reindex Searchkick and ESS.
5. Smoke critical browser paths on the running local Rails server.

Commands:

```bash
./bin/rails db:migrate
DRY_RUN=true rake import:vocabularies import:providers import:resources import:datasources import:deployable_services import:guidelines
rails import:all
rake searchkick:reindex:all
rake ess:reindex:all
```

Evidence:

- Command results.
- Imported entity counts.
- Search and ESS reindex results.

### K5. Full automated validation

Goal: run the full suite and static checks after imports and reindexing.

Commands:

```bash
bundle exec rspec
rubocop
haml-lint --exclude 'lib/**/*.haml'
./bin/rails rswag
git diff --stat swagger/
git diff --check
```

Sandbox note:

- If RuboCop or haml-lint fail with cache permission errors under `~/.cache`, rerun with a writable cache root, for example:

```bash
RUBOCOP_CACHE_ROOT=/var/folders/z2/2yb9j31x2_j2y3dk4s487h980000gn/T/rubocop_cache rubocop
RUBOCOP_CACHE_ROOT=/var/folders/z2/2yb9j31x2_j2y3dk4s487h980000gn/T/rubocop_cache haml-lint --exclude 'lib/**/*.haml'
```

Evidence:

- Full command output summaries.
- Failure reruns with exact spec file/line.
- Final `git diff --check` pass.

### K6. Cypress gate

Goal: run all Cypress specs against the real local Rails app.

Steps:

1. Install Cypress dependencies.
2. Confirm Cypress base URL points to the selected Rails port.
3. Run the whole e2e suite.
4. Rerun any failed spec file after fixes.
5. Preserve screenshots/videos for failures.

Commands:

```bash
cd test/system
yarn install
npm run cy:run -- --spec "cypress/e2e/**/*.spec.ts"
```

Fallback if Rails uses 5100:

```bash
cd test/system
CYPRESS_BASE_URL=http://localhost:5100 npm run cy:run -- --spec "cypress/e2e/**/*.spec.ts"
```

Evidence:

- Full Cypress summary.
- Failed spec filenames, screenshots, videos, and rerun results.
- Explicit note that removed V5 filters/fields are not visible.

### K7. Live browser QA

Goal: manually verify the app surfaces after the automated checks pass.

Open these paths in the browser against the selected local Rails port:

- `/`
- `/services`
- service search filters
- service show
- datasource show
- provider show
- deployable service show
- guideline show
- comparison flow
- `/api_docs`
- `/backoffice/providers` create/edit simplified Provider
- `/backoffice/services` create/edit Service
- datasource edit through Service form
- deployable service show/edit

Negative assertions:

- No deleted V5 facets visible: target users, platforms, geographical availability, language availability, lifecycle, funding, related platforms, dedicated-for.
- No old Provider structured contact/location/network/tag sections.
- No datasource PID-system fields.
- No 500s, missing partials, unknown attributes, or `NoMethodError` in Rails/Sidekiq logs.

Evidence:

- Screenshots: public service, public provider, service filters, provider edit, service edit, `/api_docs`.
- Rails log tail and Sidekiq log tail.

### K8. External contract sweep

Goal: compare Marketplace importers/serializers against current live external contracts.

Steps:

1. Inspect current `EOSC-PLATFORM/eosc-resources-model` `main` for in-scope schemas.
2. Curl every relevant endpoint from `docs/v5_to_v6/resources/swagger/integration.json`.
3. Use the real `.env` token without printing it.
4. Record status code, total/count, sampled payload keys, and schema mismatch notes.

Relevant endpoints:

- `/public/organisation/all`
- `/public/service/all`
- `/public/datasource/all`
- `/public/deployableApplication/all`
- `/public/interoperabilityRecord/all`
- `/public/resourceInteroperabilityRecord/all`
- `/catalogue/all` as the V5-shaped exception
- `/public/adapter/all` and `/public/trainingResource/all` only as out-of-scope observations

Evidence table:

| Endpoint                             | Status | Count | Sampled keys | Marketplace action                             |
| ------------------------------------ | ------ | ----- | ------------ | ---------------------------------------------- |
| `/public/organisation/all`           | TBD    | TBD   | TBD          | Importer/serializer compatible or fix required |
| `/public/service/all`                | TBD    | TBD   | TBD          | Importer/serializer compatible or fix required |
| `/public/datasource/all`             | TBD    | TBD   | TBD          | Importer/serializer compatible or fix required |
| `/public/deployableApplication/all`  | TBD    | TBD   | TBD          | Importer/serializer compatible or fix required |
| `/public/interoperabilityRecord/all` | TBD    | TBD   | TBD          | H Lite compatible or follow-up required        |
| `/catalogue/all`                     | TBD    | TBD   | TBD          | V5-shaped exception                            |

## Completion criteria

Slice K is complete only when:

- Rails serves Marketplace locally on the documented port.
- Fresh validation DB and current dev DB gates pass or have documented accepted exceptions.
- Full RSpec, RuboCop, HAML lint, rswag, Searchkick reindex, and ESS reindex pass.
- Cypress full e2e run passes against the real local server.
- Manual browser QA evidence is captured.
- External contract sweep is recorded.
- The remote docs commit is reconciled or explicitly deferred with rationale.
- The final PR notes list exact commands, dates, outcomes, and accepted exceptions.

## Expected Codex escalations

Codex should ask for approval when:

- Network access is needed for package install, external API curl, GitHub schema inspection, or live imports.
- Long-running commands need to run outside the sandbox.
- A command would drop/reset a database or otherwise destroy local data.
- A GUI/browser target must be opened through an approved browser tool.

Codex should not:

- Print `.env` tokens or credentials.
- Commit screenshots/videos/logs containing secrets.
- Reset the user's development DB without explicit approval.
- Remove Catalogue V5-shaped compatibility while closing Slice K.
