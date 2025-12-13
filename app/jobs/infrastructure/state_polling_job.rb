# frozen_string_literal: true

class Infrastructure::StatePollingJob < ApplicationJob
  queue_as :default

  # Poll all active infrastructures that need state updates
  def perform(infrastructure_id = nil)
    infrastructure_id ? poll_single(infrastructure_id) : poll_all_pending
  end

  private

  def poll_single(infrastructure_id)
    infrastructure = Infrastructure.find_by(id: infrastructure_id)
    return unless infrastructure&.im_infrastructure_id.present?
    return if infrastructure.destroyed? || infrastructure.failed?

    update_infrastructure_state(infrastructure)
  end

  def poll_all_pending
    Infrastructure.pending_state_check.find_each do |infrastructure|
      next unless infrastructure.im_infrastructure_id.present?

      update_infrastructure_state(infrastructure)
    rescue StandardError => e
      Rails.logger.error "Failed to poll Infrastructure #{infrastructure.id}: #{e.message}"
      infrastructure.update_columns(last_state_check_at: Time.current)
    end
  end

  def update_infrastructure_state(infrastructure)
    im_client = InfrastructureManager::Client.new
    result = im_client.get_state(infrastructure.im_infrastructure_id)

    if result[:success]
      im_state = result[:data]&.dig("state")
      infrastructure.update_state_from_im!(im_state)

      # If running, also fetch outputs
      fetch_outputs(infrastructure, im_client) if infrastructure.running?
    else
      Rails.logger.warn "Could not get state for Infrastructure #{infrastructure.id}: #{result[:error]}"
      infrastructure.update_columns(last_state_check_at: Time.current)
    end
  end

  def fetch_outputs(infrastructure, im_client)
    return if infrastructure.outputs.present? && infrastructure.outputs["jupyterhub_url"].present?

    result = im_client.get_outputs(infrastructure.im_infrastructure_id)
    return unless result[:success] && result[:data]

    outputs = result[:data]["outputs"] || {}
    infrastructure.update_columns(outputs: outputs) if outputs.present?

    # Update project_item deployment_link if we got a better URL
    update_project_item_link(infrastructure, outputs)
  end

  def update_project_item_link(infrastructure, outputs)
    jupyterhub_url = outputs["jupyterhub_url"]
    return unless jupyterhub_url.present?

    project_item = infrastructure.project_item
    return if project_item.deployment_link == jupyterhub_url

    project_item.update!(deployment_link: jupyterhub_url, status: "Deployment ready at #{jupyterhub_url}")
  end
end
