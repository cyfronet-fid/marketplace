# frozen_string_literal: true

class DeployableService::PcCreateOrUpdateJob < ApplicationJob
  queue_as :pc_subscriber

  rescue_from(Errno::ECONNREFUSED) { |exception| raise exception }

  def perform(deployable_service, status)
    DeployableService::PcCreateOrUpdate.new(deployable_service, status).call
  end
end
