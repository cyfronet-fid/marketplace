# frozen_string_literal: true

class Provider::PcCreateOrUpdate
  def initialize(eic_provider, logger)
    @eic_provider =  eic_provider
    @eid = eic_provider["id"]
    @logger = logger
  end

  def call
    prov = map_provider(@eic_provider)
    mapped_provider = Provider.joins(:sources).find_by("provider_sources.source_type": "eic",
                                                       "provider_sources.eid": @eid)
    if mapped_provider.nil?
      provider = Provider.new(prov)
      if provider.save!
        ProviderSource.create!(provider_id: provider.id, source_type: "eic", eid: @eid)
        log "Provider created successfully #{provider.id}"
      end
      provider
    else
      mapped_provider.update(prov)
      log "Provider updated successfully #{mapped_provider.id}"
      mapped_provider
    end
  end

  private
    def map_provider(data)
      {
        "name": data["name"]
      }
    end

    def log(msg)
      @logger.info(msg)
    end
end
