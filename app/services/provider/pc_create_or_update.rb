# frozen_string_literal: true

class Provider::PcCreateOrUpdate
  def initialize(eic_provider, modified_at)
    @eic_provider =  eic_provider
    @eid = eic_provider["id"]
    @modified_at = modified_at
  end

  def call
    provider_hash = Importers::Provider.new(@eic_provider, @modified_at).call
    mapped_provider = Provider.joins(:sources).find_by("provider_sources.source_type": "eic",
                                                       "provider_sources.eid": @eid)
    if mapped_provider.nil?
      mapped_provider = Provider.new(provider_hash)
      if mapped_provider.save!
        provider_source = ProviderSource.create!(provider_id: mapped_provider.id, source_type: "eic", eid: @eid)
        Importers::Logo.new(mapped_provider, @eic_provider["logo"]).call
      end
    else
      mapped_provider.update(provider_hash)
      provider_source = mapped_provider.sources.find_by(source_type: "eic")
      Importers::Logo.new(mapped_provider, @eic_provider["logo"]).call
    end
    if provider_source.present?
      mapped_provider.update(upstream_id: provider_source.id)
    end
    mapped_provider
  end
end
