# frozen_string_literal: true

class Infrastructure::DestroyJob < ApplicationJob
  queue_as :default

  def perform(infrastructure_id)
    infrastructure = Infrastructure.find_by(id: infrastructure_id)
    return unless infrastructure&.can_destroy?

    Rails.logger.info "Destroying Infrastructure #{infrastructure.id} (IM ID: #{infrastructure.im_infrastructure_id})"

    im_client = InfrastructureManager::Client.new
    result = im_client.destroy_infrastructure(infrastructure.im_infrastructure_id)

    if result[:success]
      infrastructure.mark_destroyed!
      update_project_item_status(infrastructure, :destroyed)
      Rails.logger.info "Infrastructure #{infrastructure.id} destroyed successfully"
    else
      error_message = result[:error] || "Unknown error"
      Rails.logger.error "Failed to destroy Infrastructure #{infrastructure.id}: #{error_message}"
      infrastructure.mark_failed!("Destroy failed: #{error_message}")
      update_project_item_status(infrastructure, :failed, error_message)
    end
  rescue StandardError => e
    Rails.logger.error "Destroy job failed for Infrastructure #{infrastructure_id}: #{e.class}: #{e.message}"
    infrastructure&.mark_failed!(e.message)
  end

  private

  def update_project_item_status(infrastructure, status, error_message = nil)
    project_item = infrastructure.project_item

    case status
    when :destroyed
      project_item.update!(status: "Infrastructure has been destroyed", status_type: :closed)
    when :failed
      project_item.update!(status: "Failed to destroy infrastructure: #{error_message}", status_type: :rejected)
    end
  end
end
