# V6 PC Import Cleanup Runbook

Use this runbook after deploying the V6 import fixes if an environment already has stale or repeated PC-imported records.

Run every destructive command in a Rails console only after inspecting the records it will touch:

```bash
bin/rails console
```

## Repeated Providers

Find imported provider source IDs that point to more than one MP provider:

```ruby
dupe_sources =
  ProviderSource.where(source_type: "eosc_registry").group(:eid).having("COUNT(DISTINCT provider_id) > 1").count

dupe_sources.keys
```

Inspect one duplicated provider group:

```ruby
eid = dupe_sources.keys.first
providers =
  Provider
    .joins(:sources)
    .where(provider_sources: { source_type: "eosc_registry", eid: eid })
    .distinct
    .includes(:sources, :alternative_identifiers)

providers.map do |provider|
  {
    id: provider.id,
    pid: provider.pid,
    name: provider.name,
    status: provider.status,
    upstream_id: provider.upstream_id,
    source_ids: provider.sources.map { |source| [source.id, source.eid] },
    service_ids: Service.where(resource_organisation_id: provider.id).pluck(:id),
    provided_service_ids: provider.service_providers.pluck(:service_id)
  }
end
```

Choose the canonical provider. Prefer the provider whose `pid` equals the PC `id`, has the newest `synchronized_at`, and owns the correct `ProviderSource`.

```ruby
canonical = providers.max_by { |provider| [provider.synchronized_at || Time.zone.at(0), provider.id] }
stale = providers.where.not(id: canonical.id)
```

Move safe associations from stale providers to the canonical provider:

```ruby
stale.find_each do |provider|
  Service.where(resource_organisation_id: provider.id).update_all(resource_organisation_id: canonical.id)

  provider.service_providers.find_each do |service_provider|
    ServiceProvider.find_or_create_by!(service_id: service_provider.service_id, provider_id: canonical.id)
    service_provider.destroy!
  end

  provider
    .sources
    .where(source_type: "eosc_registry")
    .find_each do |source|
      next if canonical.sources.exists?(source_type: source.source_type, eid: source.eid)

      source.update!(provider: canonical)
    end

  provider.update!(status: :deleted)
end

canonical.update!(upstream: canonical.sources.find_by!(source_type: "eosc_registry", eid: eid))
```

Refresh indexes:

```ruby
Provider.reindex
Service.reindex
```

## Repeated Datasources

Find imported datasource source IDs that point to more than one MP service/datasource:

```ruby
dupe_datasource_sources =
  ServiceSource
    .joins(:service)
    .where(source_type: "eosc_registry", services: { type: "Datasource" })
    .group(:eid)
    .having("COUNT(DISTINCT service_id) > 1")
    .count

dupe_datasource_sources.keys
```

Inspect one duplicated datasource group:

```ruby
eid = dupe_datasource_sources.keys.first
datasources =
  Datasource
    .joins(:sources)
    .where(service_sources: { source_type: "eosc_registry", eid: eid })
    .distinct
    .includes(:sources)

datasources.map do |datasource|
  {
    id: datasource.id,
    pid: datasource.pid,
    name: datasource.name,
    status: datasource.status,
    upstream_id: datasource.upstream_id,
    source_ids: datasource.sources.map { |source| [source.id, source.eid] },
    offers_count: datasource.offers.count,
    project_items_count: datasource.project_items.count
  }
end
```

Choose the canonical datasource, then soft-delete stale records. Do not merge records with orders or offers without confirming the impact with product owners.

```ruby
canonical = datasources.max_by { |datasource| [datasource.synchronized_at || Time.zone.at(0), datasource.id] }
stale = datasources.where.not(id: canonical.id)

stale.find_each do |datasource|
  if datasource.offers.exists? || datasource.project_items.exists?
    puts "Skipping datasource #{datasource.id}: has offers or project items"
    next
  end

  datasource
    .sources
    .where(source_type: "eosc_registry")
    .find_each do |source|
      next if canonical.sources.exists?(source_type: source.source_type, eid: source.eid)

      source.update!(service: canonical)
    end

  datasource.update!(status: :deleted)
end

canonical.update!(upstream: canonical.sources.find_by!(source_type: "eosc_registry", eid: eid))
```

Refresh indexes:

```ruby
Datasource.reindex
Service.reindex
```
