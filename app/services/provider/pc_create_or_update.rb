# frozen_string_literal: true

class Provider::PcCreateOrUpdate
  def initialize(eic_provider, modified_at)
    @eic_provider =  eic_provider
    @eid = eic_provider["id"]
    @modified_at = modified_at
  end

  def call
    prov = Importers::Provider.new(@eic_provider, @modified_at).call
    mapped_provider = Provider.joins(:sources).find_by("provider_sources.source_type": "eic",
                                                       "provider_sources.eid": @eid)
    if mapped_provider.nil?
      provider = Provider.new(prov)
      if provider.save!
        ProviderSource.create!(provider_id: provider.id, source_type: "eic", eid: @eid)
        Importers::Logo.new(mapped_provider, @eic_provider["logo"]).call
      end
      provider
    else
      mapped_provider.update(prov)
      Importers::Logo.new(mapped_provider, @eic_provider["logo"]).call
      mapped_provider
    end
  end
end
