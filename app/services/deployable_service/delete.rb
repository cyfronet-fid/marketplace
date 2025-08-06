# frozen_string_literal: true

class DeployableService::Delete
  def initialize(deployable_service_eid, source: "eosc_registry")
    @deployable_service =
      DeployableService.joins(:sources).find_by(
        "deployable_service_sources.source_type": source,
        "deployable_service_sources.eid": deployable_service_eid
      )
  end

  def call
    if @deployable_service
      @deployable_service.destroy
      @deployable_service
    end
  end
end
