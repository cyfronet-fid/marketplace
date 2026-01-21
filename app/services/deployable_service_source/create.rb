# frozen_string_literal: true

class DeployableServiceSource::Create < ApplicationService
  def initialize(deployable_service, source_type = "eosc_registry")
    super()
    @deployable_service = deployable_service
    @source_type = source_type
  end

  def call
    new_source =
      DeployableServiceSource.create(
        deployable_service_id: @deployable_service.id,
        source_type: @source_type,
        eid: @deployable_service.pid,
        errored: @deployable_service.errors.to_hash
      )
    @deployable_service.update(upstream_id: new_source.id)
  end
end
