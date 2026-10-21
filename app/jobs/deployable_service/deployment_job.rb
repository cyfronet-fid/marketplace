# frozen_string_literal: true

class DeployableService::DeploymentJob < ApplicationJob
  queue_as :deployments

  def perform(project_item)
    Rails.logger.info "Starting deployment for ProjectItem #{project_item.id} (#{project_item.offer&.name})"
    Infrastructure::Deploy.call(project_item)
  end
end
