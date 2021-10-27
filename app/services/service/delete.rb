# frozen_string_literal: true

class Service::Delete
  def initialize(service_eid, source: "eosc_registry")
    @service = Service.joins(:sources).find_by("service_sources.source_type": source,
                                               "service_sources.eid": service_eid)
  end

  def call
    return unless @service

    @service.update(status: :deleted)
    @service.offers.each { |o| Offer::Draft.new(o).call }
    @service
  end
end
