# frozen_string_literal: true

class Provider::PcCreateOrUpdate < ApplicationService
  def initialize(eosc_registry_provider, status, modified_at)
    super()
    @eosc_registry_provider = eosc_registry_provider
    @eid = eosc_registry_provider["id"]
    @status = status
    @modified_at = modified_at
  end

  def call
    provider_hash = Importers::Provider.call(@eosc_registry_provider, @modified_at)
    mapped_provider =
      Provider.joins(:sources).find_by("provider_sources.source_type": "eosc_registry", "provider_sources.eid": [@eid])
    if mapped_provider.nil?
      mapped_provider = Provider.new(provider_hash)
      mapped_provider.set_default_logo
      mapped_provider.status = @status
      if mapped_provider.save!
        provider_source =
          ProviderSource.create!(provider_id: mapped_provider.id, source_type: "eosc_registry", eid: @eid)
      end
    else
      mapped_provider.update(provider_hash)
      provider_source = mapped_provider.sources.find_by(source_type: "eosc_registry")
      mapped_provider.status = @status
    end
    mapped_provider.update(upstream_id: provider_source.id) if provider_source.present?

    Importers::Logo.new(mapped_provider, @eosc_registry_provider["logo"]).call
    mapped_provider.save!
    mapped_provider
  end
end
