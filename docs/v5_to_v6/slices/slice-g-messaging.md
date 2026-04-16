# Slice G: Messaging — JMS + AMS (1.5d)

Cross-cutting topic renames and new message routing. Models and importers are already done by Slices B–F; this slice only updates the dispatch layer.

**Depends on Slice 0 decisions:** D5 (AMS topic names for new entity types), D11 (`DataSource` capital-S → STI `Datasource`), D18 (URL suffixes for any orchestrator-style HTTP calls these services make).

**Depends on Slices B–F:** the models / importers / jobs (`Provider::PcCreateOrUpdateJob`, etc.) must exist under their current names BEFORE this slice ships. Slice G does NOT rename Rails classes — it only remaps inbound topic strings to those existing jobs.

---

## Rename map (authoritative)

| V5 topic/resource_type          | V6 topic/resource_type          | Rails handler (unchanged)                                                                                       |
| ------------------------------- | ------------------------------- | --------------------------------------------------------------------------------------------------------------- |
| `provider.*`                    | `organisation.*`                | `Provider::PcCreateOrUpdateJob`, `Provider::DeleteJob`                                                          |
| `deployable_software.*`         | `deployable_application.*`      | `DeployableService::PcCreateOrUpdateJob`, `DeployableService::DeleteJob`                                        |
| `service.*` / `infra_service.*` | `service.*` / `infra_service.*` | unchanged                                                                                                       |
| `datasource.*`                  | `datasource.*`                  | unchanged (D11 mapping lives in the importer, not the router)                                                   |
| `catalogue.*`                   | `catalogue.*`                   | unchanged                                                                                                       |
| `interoperability_record.*`     | `interoperability_record.*`     | `Guideline::PcCreateOrUpdateJob` (alias lives inside `Ams::ManageMessage`; need to add to `Jms::ManageMessage`) |
| (new) `adapter.*`               | `adapter.*`                     | `Adapter::*` jobs — **only if Slice I ships**                                                                   |
| (new) `training_resource.*`     | `training_resource.*`           | `TrainingResource::*` jobs — **only if Slice I ships**                                                          |

---

## G1. Update `Jms::ManageMessage` topic routing (45 min)

**File:** `app/services/jms/manage_message.rb`

### Add an alias layer at the top of `call`

Current code derives `resource_type` from the destination header (e.g. `foo.provider.update` → `provider`). V6 changes that header to `foo.organisation.update`. Add a normalisation step so the `case` branches keep their existing (internal) names — avoids renaming `when "provider"` → `when "organisation"` everywhere, and avoids touching the `Provider::PcCreateOrUpdateJob` chain:

```ruby
INBOUND_TOPIC_ALIASES = {
  "organisation" => "provider",
  "deployable_application" => "deployable_service",
  "interoperability_record" => "guideline"
}.freeze

def call
  log @message
  body = JSON.parse(@message.body)
  raw_type = @message.headers["destination"].split(".")[-2]
  resource_type = INBOUND_TOPIC_ALIASES.fetch(raw_type, raw_type)
  action = @message.headers["destination"].split(".").last
  resource = body[raw_type.camelize(:lower)] || body[resource_type.camelize(:lower)]

  raise Importable::ResourceParseError, "Cannot parse resource" if resource.nil? || resource.empty?

  case resource_type
  when "service", "infra_service"
    # ...existing...
  when "provider"
    # ...existing, no rename needed...
  when "catalogue"
    # ...existing...
  when "datasource"
    # ...existing...
  when "deployable_service"
    # ...existing...
  when "guideline"
    modified_at = modified_at(body)
    case action
    when "delete"
      Guideline::DeleteJob.perform_later(resource["id"])
    when "update", "create"
      Guideline::PcCreateOrUpdateJob.perform_later(
        resource,
        object_status(body["active"], body["suspended"]),
        modified_at
      )
    end
  else
    raise Importable::WrongMessageError
  end
  # ...
end
```

### Key change

- **Read both** `body[raw_type.camelize(:lower)]` AND the fallback `body[resource_type.camelize(:lower)]` so messages published with either the V5 key (`"provider"`) or the V6 key (`"organisation"`) both work while Athena is mid-cutover. Remove the fallback after the cutover stabilises (track in Slice J).
- **Add the `when "guideline"` branch** — currently `Jms::ManageMessage` has no guideline routing (only `Ams::ManageMessage` does). Copy from `ams/manage_message.rb:89-100` (see G2).

### Validate

```bash
grep -cE "INBOUND_TOPIC_ALIASES" app/services/jms/manage_message.rb
# Should return 1

grep -cE 'when "guideline"' app/services/jms/manage_message.rb
# Should return 1
```

---

## G2. Update `Ams::ManageMessage` topic routing (30 min)

**File:** `app/services/ams/manage_message.rb`

AMS topic format is `mp-${model}-${action}`. The existing parser (`@topic.split(/[-.]/)`) pulls `model` = `resource_type`. Add the same alias table as JMS:

```ruby
INBOUND_TOPIC_ALIASES = {
  "organisation" => "provider",
  "deployable_application" => "deployable_service",
  "interoperability_record" => "guideline" # already handled inline; move to table for consistency
}.freeze

# inside call:
destination_parts = @topic.split(/[-.]/)
raw_type = destination_parts[-2]
resource_type = INBOUND_TOPIC_ALIASES.fetch(raw_type, raw_type)
action = destination_parts.last

resource = body[raw_type.camelize(:lower)] || body[resource_type.camelize(:lower)]
```

Remove the inline remap line `resource_type = "guideline" if resource_type == "interoperability_record"` (now in the table).

Add `when "adapter"` and `when "training_resource"` branches only if Slice I is in scope. Skeleton (match the existing pattern):

```ruby
when "adapter"
  modified_at = modified_at(body)
  case action
  when "delete"
    Adapter::DeleteJob.perform_later(resource["id"])
  else
    Adapter::PcCreateOrUpdateJob.perform_later(resource, modified_at)
  end
when "training_resource"
  modified_at = modified_at(body)
  case action
  when "delete"
    TrainingResource::DeleteJob.perform_later(resource["id"])
  else
    TrainingResource::PcCreateOrUpdateJob.perform_later(resource, modified_at)
  end
```

If Slice I is deferred, those two branches stay out until Slice I ships.

### Validate

```bash
grep -cE "INBOUND_TOPIC_ALIASES" app/services/ams/manage_message.rb
# Should return 1
grep -cE 'resource_type = "guideline" if resource_type == "interoperability_record"' app/services/ams/manage_message.rb
# Should return 0 — replaced by alias table
```

---

## G3. Update `config/ams_subscriber.yml` (15 min)

**File:** `config/ams_subscriber.yml`

Rename topics under the `topics:` key. V5 → V6:

```yaml
topics:
  - mp-catalogue-create
  - mp-catalogue-delete
  - mp-catalogue-update
  - mp-datasource-create
  - mp-datasource-delete
  - mp-datasource-update
  - mp-deployable_application-create # was mp-deployable_service-*
  - mp-deployable_application-delete
  - mp-deployable_application-update
  - mp-interoperability_record-create # unchanged
  - mp-interoperability_record-delete
  - mp-interoperability_record-update
  - mp-organisation-create # was mp-provider-*
  - mp-organisation-delete
  - mp-organisation-update
  - mp-service-create # unchanged
  - mp-service-delete
  - mp-service-update
```

If Slice I ships, add (D5 default):

```yaml
- mp-adapter-create
- mp-adapter-delete
- mp-adapter-update
- mp-training_resource-create
- mp-training_resource-delete
- mp-training_resource-update
```

**Cutover caveat (per D20):** D20 decides hard-cut vs. dual-emit. Default: hard cut — single V6 topic list above is correct. If D20 resolves to dual-emit, add the six V5 topic names (`mp-provider-*`, `mp-deployable_service-*`) back to the list temporarily. `INBOUND_TOPIC_ALIASES` + the dual-key body parse in G1/G2 already handle dual-emit on the parsing side regardless.

### Validate

```bash
grep -cE "mp-(provider|deployable_service)-" config/ams_subscriber.yml
# Should return 0 (hard cut) or 6 (dual — document why)
grep -cE "mp-(organisation|deployable_application)-" config/ams_subscriber.yml
# Should return 6
```

---

## G4. Update `config/stomp_subscriber.yml` (10 min)

**File:** `config/stomp_subscriber.yml`

Current config uses a single `topic:` placeholder sourced from ENV/credentials (`MP_STOMP_DESTINATION`). The topic NAME is set in the env, not the file — but the subscription only reads ONE topic. Action:

1. **Per D23:** confirm with ops what `MP_STOMP_DESTINATION` is set to in production (likely a wildcard like `*.provider.*`). If it is a wildcard pattern, update production env to `*.organisation.*,*.deployable_application.*,*.service.*,*.datasource.*,*.catalogue.*,*.interoperability_record.*`. If D23 default applies (ops ticket deferred), leave the current ENV alone and track the cutover as a separate devops task.

2. Document the new ENV values in `.env.example` and `README.md`:

   ```
   # V6 destinations — wildcards, comma-separated if subscriber supports it
   MP_STOMP_DESTINATION=*.organisation.*,*.service.*,*.catalogue.*,*.datasource.*,*.deployable_application.*,*.interoperability_record.*
   ```

3. If the STOMP client only accepts a single destination per subscription, add multiple entries under `subscriptions:` — one per topic prefix. Test locally with `docker compose up activemq` before merging.

No YAML code change — all driven by env vars and their cutover. Open a follow-up issue tagged "devops" if ops needs a ticket to update the credential.

### Validate

```bash
# Nothing automated — must be verified by ops against prod credential.
# Manual: grep current value
grep -n "MP_STOMP_DESTINATION" .env.example
# Should exist and list V6 topics
```

---

## G5. `modifiedAt` date handling — audit, do NOT change (15 min)

**Files:**

- `app/services/jms/manage_message.rb:92-95` (`modified_at` helper)
- `app/services/ams/manage_message.rb:116-119` (`modified_at` helper)

### Scope

V6 uses ISO 8601 (`YYYY-MM-DD`) for entity attribute fields (`publishingDate`, `versionDate`, `lastUpdate`) inside the resource body — **not** for the JMS/AMS `metadata.modifiedAt` envelope field. `metadata.modifiedAt` stays **Unix milliseconds since epoch** in V6. `Time.at(modifiedAt.to_i / 1000)` in both services is correct.

### Action

- **Do NOT change** `modified_at` helpers. Leave them alone.
- Add a one-line comment so a future reader does not "fix" this:

  ```ruby
  def modified_at(body)
    m = body.dig("metadata", "modifiedAt")
    m ? Time.at(m.to_i / 1000) : Time.now # V6 keeps Unix ms; ISO 8601 applies to entity attribute fields only
  end
  ```

- Confirm by tailing real JMS messages in staging after Athena cuts over:
  ```
  log @message
  ```
  If `modifiedAt` shows up as a string `"2026-03-15"`, that is a breaking change — file a new issue, do NOT attempt to handle both formats inline (premature flexibility).

---

## G6. `PcCreateOrUpdate` services — verify, do NOT rewrite (20 min)

**Files:**

- `app/services/provider/pc_create_or_update.rb`
- `app/services/service/pc_create_or_update.rb`
- `app/services/datasource/pc_create_or_update.rb`
- `app/services/deployable_service/pc_create_or_update.rb`
- `app/services/catalogue/pc_create_or_update.rb`
- `app/services/guideline/pc_create_or_update.rb`

Each of these calls the entity-specific `Importers::*` that Slices B–F rewrote. The only thing to double-check in Slice G is that the `resource` Hash passed in is the FLAT V6 body (not a `{"provider": {...}}` wrapped object). The alias layer in G1/G2 (`body[raw_type.camelize(:lower)] || body[resource_type.camelize(:lower)]`) handles the unwrap.

Grep confirmation:

```bash
for f in app/services/{provider,service,datasource,deployable_service,catalogue,guideline}/pc_create_or_update.rb; do
  echo "=== $f ==="
  sed -n '1,40p' "$f"
done
```

Expect each to call `Importers::*.call(resource, ...)` and nothing else requiring a V5-only shape.

### Non-public resource IDs (README line 41)

V6 appends `00` to non-public resource IDs. We consume the public endpoints only (`public/*/all` and JMS messages for active resources). Both cases give plain IDs. No action. If staging logs show inbound messages with `00`-suffixed IDs routed to our subscriber, investigate — those shouldn't reach us.

---

## G7. Outbound publisher — check `app/services/jms/publish.rb` (20 min)

**Files:**

- `config/stomp_publisher.yml`
- `app/services/jms/publish.rb` (if present — via `Propagable` concern)

If MP publishes events back to the PC (via `Propagable#propagate`), verify the destination topic names MP produces. Grep:

```bash
rg -n "organisation\\.|provider\\.|deployable_application\\.|deployable_software\\." app/ config/
```

For each hit that produces `provider.create`/`deployable_software.*`, rename to `organisation.*`/`deployable_application.*`.

If `Propagable#propagate` uses `self.class.name.underscore` to build the topic — that gives `provider.*` and `deployable_service.*`. Add a `publish_topic_name` override on `Provider` returning `"organisation"` and on `DeployableService` returning `"deployable_application"`.

Skeleton:

```ruby
# app/models/provider.rb
def publish_topic_name
  "organisation"
end
```

Update `Propagable` to prefer `publish_topic_name` when defined:

```ruby
# app/models/concerns/propagable.rb
def _topic_resource_name
  respond_to?(:publish_topic_name) ? publish_topic_name : self.class.name.underscore
end
```

### Validate

```bash
rg -nE "(provider|deployable_software)\\.(create|update|delete)" app/ config/
# Should return 0 outside tests or obvious V5 compat shims
```

---

## G8. Specs (20 min)

**Files:**

- `spec/services/jms/manage_message_spec.rb`
- `spec/services/ams/manage_message_spec.rb`

Add test cases:

- Incoming message with `destination = "foo.organisation.update"` routes to `Provider::PcCreateOrUpdateJob`.
- Incoming message with `destination = "foo.deployable_application.create"` routes to `DeployableService::PcCreateOrUpdateJob`.
- Incoming message with `destination = "foo.interoperability_record.update"` routes to `Guideline::PcCreateOrUpdateJob` (both JMS and AMS).
- Legacy `destination = "foo.provider.update"` still routes correctly during cutover.

Reuse existing fixtures in `spec/fixtures/stomp/` — just copy a provider message and swap the destination header.

### Validate

```bash
bundle exec rspec spec/services/jms/manage_message_spec.rb spec/services/ams/manage_message_spec.rb
```

---

## Validate (full slice)

```bash
bundle exec rspec spec/services/jms/ spec/services/ams/ spec/jobs/

# AMS config sanity:
grep -cE "mp-(organisation|deployable_application)-(create|delete|update)" config/ams_subscriber.yml
# Should return 6 (or 12 if Slice I also ships with adapter + training_resource)

# No stray V5 outbound names:
rg -nE "(provider|deployable_software)\\.(create|update|delete)" app/ config/
# Empty

# Local integration (optional):
docker compose up -d activemq
bundle exec rails runner '
  require "stomp"
  c = Stomp::Client.open("stomp://admin:admin@localhost:61613")
  c.publish("/topic/eosc.organisation.update", File.read("spec/fixtures/stomp/provider_update.json"), { persistent: true })
  sleep 1
'
# Check sidekiq log: Provider::PcCreateOrUpdateJob enqueued
```

**Commit.**

---

## Out of scope

- Adapter / TrainingResource topics — gated on Slice I (D5 default topic names pre-registered with Athena).
- STOMP broker migration / credential rotation — ops task.
- Hard-deletion of `INBOUND_TOPIC_ALIASES` table after cutover stabilises — **Slice J** cleanup.
- Renaming Rails classes `Provider` → `Organisation`, `DeployableService` → `DeployableApplication` — explicitly NOT in this migration's scope.
