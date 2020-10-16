# frozen_string_literal: true

class Service::Delete
  def initialize(service_eid, source: "eic")
    @service = Service.joins(:sources).find_by("service_sources.source_type": source,
                                               "service_sources.eid": service_eid)
  end

  def call
    if @service
      @service.update(status: :deleted)
      @service.offers.each { |o| Offer::Draft.new(o).call }
      @service
    end
  end
end
