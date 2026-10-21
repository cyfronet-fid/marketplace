# frozen_string_literal: true

# Updates an infrastructure, and its project item, from the status of its ADM deployment.
class Infrastructure::RefreshState < ApplicationService
  def initialize(infrastructure, client: Adm::Client.new)
    super()
    @infrastructure = infrastructure
    @client = client
  end

  def call
    deployment = @client.deployment(@infrastructure.deployment_id)

    case deployment.status
    when "pending"
      @infrastructure.mark_creating!
    when "configured"
      @infrastructure.mark_configured!
      store_outputs(deployment.outputs)
    when "running", "stopped", "off"
      # "stopped"/"off" still considered running (infrastructure exists)
      @infrastructure.mark_running!(deployment.outputs.presence || @infrastructure.outputs)
      update_deployment_link
    when "failed", "unconfigured"
      fail!(deployment.details.presence || "ADM reported deployment status: #{deployment.status}")
    when "deleted"
      @infrastructure.mark_destroyed!
      Infrastructure::ProjectItemStatus.closed!(@infrastructure.project_item)
    else
      # "deleting"/"unknown" - the deployment is still there, check again later
      @infrastructure.record_state_check!
    end
  rescue Adm::NotFound => e
    fail!(e.message)
  end

  private

  def store_outputs(outputs)
    @infrastructure.update!(outputs: outputs) if outputs.present?
    update_deployment_link
  end

  def update_deployment_link
    deployment_url = @infrastructure.deployment_url
    project_item = @infrastructure.project_item
    return if deployment_url.blank? || project_item.deployment_link == deployment_url

    Infrastructure::ProjectItemStatus.ready!(project_item, deployment_url)
  end

  def fail!(error)
    @infrastructure.mark_failed!(error)
    Infrastructure::ProjectItemStatus.rejected!(
      @infrastructure.project_item,
      "Deployment failed: #{error}. Please contact support."
    )
  end
end
