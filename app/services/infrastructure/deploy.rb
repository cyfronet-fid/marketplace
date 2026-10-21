# frozen_string_literal: true

# Deploys the deployable service of a project item through ADM: registers the allocation of the
# default cloud site and creates the deployment. Its progress is tracked by Infrastructure::StatePollingJob.
class Infrastructure::Deploy < ApplicationService
  def initialize(project_item, client: Adm::Client.new, config: Rails.application.config_for(:adm))
    super()
    @project_item = project_item
    @client = client
    @config = config
  end

  def call
    infrastructure = create_infrastructure
    template = DeployableService::ToscaTemplate.fetch(deployable_service.url)
    infrastructure.update!(output_names: template.output_names)

    allocation_id = @client.create_allocation(**cloud_site.slice(:host, :domain))
    infrastructure.update!(allocation_id: allocation_id)

    deployment_id =
      @client.create_deployment(
        allocation_id: allocation_id,
        application_id: deployable_service.pid,
        inputs: DeployableService::DeploymentInputs.call(@project_item, template)
      )

    infrastructure.mark_created!(deployment_id)
  rescue StandardError => e
    Rails.error.report(e, context: { project_item_id: @project_item.id })
    infrastructure&.mark_failed!(e.message)

    Infrastructure::ProjectItemStatus.rejected!(
      @project_item,
      "Deployment failed: #{e.message}. Please contact support."
    )
  end

  private

  def create_infrastructure
    Infrastructure.create!(
      project_item: @project_item,
      api_base_url: @client.base_url,
      cloud_site: cloud_site_name,
      state: "pending"
    )
  end

  def deployable_service
    @project_item.offer.deployable_service
  end

  def cloud_site_name
    @config[:default_cloud_site]
  end

  def cloud_site
    @config[:cloud_sites][cloud_site_name.to_sym] || raise(Adm::Error,
                                                           "Cloud site #{cloud_site_name} is not configured")
  end
end
