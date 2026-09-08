# Deployment variants

`marketplace`, `pl-marketplace`, and `whitelabel-marketplace` are consolidating
onto this single codebase (ADR-0001: single codebase over per-node forks).
Which node a running process behaves as is selected at boot by the
`MARKETPLACE_VARIANT` env var (`marketplace` / `pl` / `whitelabel`), validated
against `config/variants.yml` and exposed via `Mp::Variant` (`lib/mp/variant.rb`).
Unset defaults to `marketplace`.

Use `Mp::Variant.marketplace?` / `.pl?` / `.whitelabel?` to key off it. Prefer
a config/env toggle for genuine per-deployment behavior; if two repos' code
only *looked* different but did the same thing, it was unified instead of
gated.

## What's been ported so far

- `Api::ServicesController` — `COUNTRY_NAME`/`CONTACT_EMAIL` now serve real
  data (via a restored `geographical_availabilities` column and a
  `Service#public_contacts` association) under `pl`/`whitelabel`; `marketplace`
  keeps its existing flat/empty behavior.
- `Api::V1::Ess::ApplicationController` — the `deployable_services` ESS
  collection/route is `marketplace`-only (the underlying `DeployableService`
  data model doesn't exist on `pl`/`whitelabel`).
- `ApplicationController#publish_user_actions_to_jms?` — JMS user-action
  publishing now actually respects `mp_stomp_publisher_enabled` (previously
  dead config on all three repos).
- `DataAdministrator#connect_user` — fixed an unguarded counter decrement.
- `Api::V1::UsersController` — fixed a 404 message referencing the wrong
  param key.
- `Importers::Token` — added the client-credentials grant (selected by
  `IMPORTER_AAI_CLIENT_SECRET` presence) alongside the existing refresh-token
  flow.
- `config.whitelabel`/`MP_WHITELABEL` was folded into `Mp::Variant.whitelabel?`.
- `config.monitoring_data_token` — no longer raises on a deployment whose
  `credentials.yml.enc` lacks the `monitoring_data` key; falls back to `nil`
  instead (all variants, not gated — a bug fix, not a behavior difference).
- `SearchLinksHelper#resource_organisation`/`#providers` — under `pl`/
  `whitelabel`, the organisation/provider name in a service's header links
  straight to the provider's own detail page; `marketplace` keeps its
  search-highlighting/preview-aware filtered-search link unchanged.

## Full details

The per-controller diffs, rationale, and audit methodology behind each of the
above live in the `arch_docs` repo, not here:

- `docs/adr/0001-single-codebase-over-per-node-forks.md` — the consolidation
  decision and migration path.
- `docs/rationale/controllers-comparison.md` and `docs/rationale/controllers/`
  — full three-way controller diff, file by file.
- `docs/rationale/whitelabel-feature-audit.md` — whitelabel's independent
  commits since the fork, sorted into verified gaps, needs-a-closer-look, and
  client-specific/excluded.

Anything not listed above under "What's been ported so far" is either not yet
reviewed, or was deliberately left out (see the audit's own client-specific
and excluded sections) — check there before assuming a given behavior has
been reconciled.
