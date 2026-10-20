# frozen_string_literal: true

class Infrastructure::StatePollingJob < ApplicationJob
  queue_as :default

  # Poll all active infrastructures that need state updates
  def perform(infrastructure_id = nil)
    infrastructure_id ? poll_single(infrastructure_id) : poll_all_pending
  end

  private

  def poll_single(infrastructure_id)
    infrastructure = deployed.active.find_by(id: infrastructure_id)
    Infrastructure::RefreshState.call(infrastructure, client: client) if infrastructure
  end

  def poll_all_pending
    deployed.pending_state_check.find_each do |infrastructure|
      Infrastructure::RefreshState.call(infrastructure, client: client)
    rescue StandardError => e
      Rails.logger.error "Failed to poll Infrastructure #{infrastructure.id}: #{e.message}"
      infrastructure.update_columns(last_state_check_at: Time.current)
    end
  end

  def deployed
    Infrastructure.adm_managed.where.not(deployment_id: nil)
  end

  def client
    @client ||= ApplicationDeploymentManager::Client.new
  end
end
