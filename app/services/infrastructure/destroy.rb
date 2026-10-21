# frozen_string_literal: true

# Deletes the ADM deployment of an infrastructure and closes its project item.
class Infrastructure::Destroy < ApplicationService
  def initialize(infrastructure, client: Adm::Client.new)
    super()
    @infrastructure = infrastructure
    @client = client
  end

  def call
    delete_deployment
    @infrastructure.mark_destroyed!
    Infrastructure::ProjectItemStatus.closed!(@infrastructure.project_item)
  rescue StandardError => e
    Rails.logger.error "Failed to destroy Infrastructure #{@infrastructure.id}: #{e.class}: #{e.message}"
    @infrastructure.mark_failed!("Destroy failed: #{e.message}")
    Infrastructure::ProjectItemStatus.rejected!(
      @infrastructure.project_item,
      "Failed to destroy infrastructure: #{e.message}"
    )
  end

  private

  def delete_deployment
    @client.delete_deployment(@infrastructure.deployment_id)
  rescue Adm::NotFound
    Rails.logger.info "Deployment of Infrastructure #{@infrastructure.id} is already gone"
  end
end
