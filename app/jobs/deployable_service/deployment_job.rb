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
      deployment_uri = extract_deployment_uri(result[:data])
      return nil unless deployment_uri

      # Extract infrastructure ID from URI and get outputs
      infrastructure_id = extract_infrastructure_id(deployment_uri)
      if infrastructure_id
        outputs_result = im_client.get_outputs(infrastructure_id)
        if outputs_result[:success] && outputs_result[:data]
          # Extract jupyterhub_url from outputs (contains the unique DNS)
          outputs = outputs_result[:data]["outputs"]
          jupyterhub_url = outputs&.dig("jupyterhub_url")
          return jupyterhub_url if jupyterhub_url
        end
      end

      # Fallback to deployment URI if we can't get outputs
      deployment_uri
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
      response_data["uri"]
    when String
      response_data.include?("http") ? response_data : nil
    else
      response_data.to_s if response_data.to_s.include?("http")
    end
  end

  def extract_infrastructure_id(uri)
    # URI format: https://deploy.sandbox.eosc-beyond.eu/im-dev/infrastructures/{id}
    return nil unless uri

    match = uri.match(%r{/infrastructures/([^/]+)})
    match&.[](1)
  end

  def extract_public_ip(vm_data)
    # VM data is in RADL format
    return nil unless vm_data

    radl = vm_data["radl"]
    return nil unless radl

    # Find the system section
    system = radl.find { |r| r["class"] == "system" }
    return nil unless system

    # Extract public IP from net_interface.1.ip (public interface)
    system["net_interface.1.ip"]
  end
end
