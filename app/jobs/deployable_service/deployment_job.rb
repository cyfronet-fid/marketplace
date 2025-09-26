# frozen_string_literal: true

class DeployableService::DeploymentJob < ApplicationJob
  queue_as :default

  def perform(project_item)
    Rails.logger.info "Starting deployment for ProjectItem #{project_item.id} (#{project_item.offer&.name})"

    filled_template = DeployableService::ToscaTemplateFiller.call(project_item)
    deployment_address = deploy_to_infrastructure_manager(project_item, filled_template)

    if deployment_address
      Rails.logger.info "Deployment successful for ProjectItem #{project_item.id}"
      project_item.update!(
        status: "Deployment ready at #{deployment_address}",
        status_type: :ready,
        deployment_link: deployment_address
      )
    else
      Rails.logger.error "Deployment failed for ProjectItem #{project_item.id}"
      project_item.update!(
        status:
          "Deployment failed - Infrastructure Manager did not return a deployment address. " \
            "Please contact support.",
        status_type: :rejected
      )
    end
  rescue StandardError => e
    Rails.logger.error "Deployment job failed for ProjectItem #{project_item.id}: #{e.class}: #{e.message}"
    project_item.update!(
      status: "Deployment failed due to system error: #{e.message}. Please contact support.",
      status_type: :rejected
    )
  end

  private

  def deploy_to_infrastructure_manager(_project_item, filled_template)
    Rails.logger.info "Deploying to Infrastructure Manager"

    # Hardcode IISAS-FedCloud now for the PoC purposes.
    im_client = InfrastructureManager::Client.new(nil, "IISAS-FedCloud")
    result = im_client.create_infrastructure(filled_template)

    if result[:success]
      extract_deployment_uri(result[:data])
    else
      Rails.logger.error "IM deployment failed: #{result[:error]}"
      nil
    end
  rescue StandardError => e
    Rails.logger.error "Infrastructure Manager deployment failed: #{e.class}: #{e.message}"
    nil
  end

  def extract_deployment_uri(response_data)
    return nil unless response_data

    case response_data
    when Hash
      response_data["uri"] || response_data[:uri]
    when String
      response_data.include?("http") ? response_data : nil
    else
      response_data.to_s if response_data.to_s.include?("http")
    end
  end
end
