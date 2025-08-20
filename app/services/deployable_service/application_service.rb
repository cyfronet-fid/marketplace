# frozen_string_literal: true

class DeployableService::ApplicationService < ApplicationService
  def initialize(deployable_service)
    super()
    @deployable_service = deployable_service
  end
end
