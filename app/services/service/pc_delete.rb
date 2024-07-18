# frozen_string_literal: true

class Service::PcDelete < Service::Delete
  def initialize(service_eid, source: "eosc_registry")
    @service =
      Service.joins(:sources).find_by("service_sources.source_type": source, "service_sources.eid": service_eid)
    super(@service)
  end

  def call
    super if @service.present?
  end
end
