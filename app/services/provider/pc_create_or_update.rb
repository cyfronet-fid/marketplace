# frozen_string_literal: true

class Provider::PcCreateOrUpdate
  def initialize(eic_provider)
    @eic_provider =  map_provider(eic_provider)
    @eid = eic_provider["id"]
  end

  def call
    mapped_provider = Provider.joins(:sources).find_by("provider_sources.source_type": "eic",
                                                       "provider_sources.eid": @eid)
    if mapped_provider.nil?
      provider = Provider.new(@eic_provider)
      if provider.save
        ProviderSource.new(provider_id: provider.id, source_type: "eic", eid: @eid).save!
      end
      provider
    else
      mapped_provider.update(@eic_provider)
      mapped_provider
    end
  end

  private
    def map_provider(data)
      {
        "name": data["name"],
      }
    end
end
