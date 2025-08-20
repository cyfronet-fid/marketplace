# frozen_string_literal: true

class DeployableService::DeleteJob < ApplicationJob
  queue_as :pc_subscriber

  def perform(deployable_service_id)
    DeployableService::Delete.new(deployable_service_id).call
  end
end
