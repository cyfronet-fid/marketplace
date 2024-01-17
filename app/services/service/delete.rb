# frozen_string_literal: true

class Service::Delete < ApplicationService
  def initialize(service_eid, source: "eosc_registry")
    super()
    @service =
      Service.joins(:sources).find_by("service_sources.source_type": source, "service_sources.eid": service_eid)
  end

  def call
    if @service
      @service.update(status: :deleted)
      @service.offers.each { |o| Offer::Draft.call(o) }
      @service
    end
  end
end
