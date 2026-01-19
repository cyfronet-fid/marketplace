# frozen_string_literal: true

class DeployableService::DeploymentJob < ApplicationJob
  queue_as :deployments

  def perform(project_item)
    Rails.logger.info "Starting deployment for ProjectItem #{project_item.id} (#{project_item.offer&.name})"

    # Create Infrastructure record to track the deployment
    infrastructure = create_infrastructure_record(project_item)

    filled_template = DeployableService::ToscaTemplateFiller.call(project_item)
    deploy_to_infrastructure_manager(project_item, infrastructure, filled_template)
  rescue StandardError => e
    Rails.logger.error "Deployment job failed for ProjectItem #{project_item.id}: #{e.class}: #{e.message}"
    infrastructure&.mark_failed!(e.message)
    project_item.update!(
      status: "Deployment failed due to system error: #{e.message}. Please contact support.",
      status_type: :rejected
    )
  end

  private

  def create_infrastructure_record(project_item)
    config = InfrastructureManager::Client.config
    Infrastructure.create!(
      project_item: project_item,
      im_base_url: config.dig(:infrastructure_manager, :base_url),
      cloud_site: config.dig(:cloud_providers, :default),
      state: "pending"
    )
  end

  def deploy_to_infrastructure_manager(project_item, infrastructure, filled_template)
    Rails.logger.info "Deploying to Infrastructure Manager"

    im_client = InfrastructureManager::Client.new
    result = im_client.create_infrastructure(filled_template)

    unless result[:success]
      Rails.logger.error "IM deployment failed: #{result[:error]}"
      handle_deployment_failure(project_item, infrastructure, result[:error])
      return
    end

    deployment_uri = extract_deployment_uri(result[:data])
    unless deployment_uri
      handle_deployment_failure(project_item, infrastructure, "No deployment URI returned")
      return
    end

    # Extract and store infrastructure ID
    im_infrastructure_id = extract_infrastructure_id(deployment_uri)
    if im_infrastructure_id
      infrastructure.mark_created!(im_infrastructure_id)
    else
      handle_deployment_failure(project_item, infrastructure, "Could not extract infrastructure ID")
      return
    end

    # Fetch outputs and complete deployment
    fetch_outputs_and_complete(project_item, infrastructure, im_client, im_infrastructure_id, deployment_uri)
  rescue StandardError => e
    Rails.logger.error "Infrastructure Manager deployment failed: #{e.class}: #{e.message}"
    handle_deployment_failure(project_item, infrastructure, e.message)
  end

  def fetch_outputs_and_complete(project_item, infrastructure, im_client, im_infrastructure_id, deployment_uri)
    outputs_result = im_client.get_outputs(im_infrastructure_id)

    if outputs_result[:success] && outputs_result[:data]
      outputs = outputs_result[:data]["outputs"] || {}
      deployment_address = outputs["jupyterhub_url"]

      if deployment_address.present?
        # We have a usable deployment URL - mark as running
        infrastructure.mark_running!(outputs)
        handle_deployment_success(project_item, deployment_address)
      else
        # Outputs fetched but no URL yet - mark as configured, polling will update
        infrastructure.mark_configured!
        handle_deployment_success(project_item, deployment_uri)
      end
    else
      # Failed to fetch outputs - mark as configured, polling will update later
      infrastructure.mark_configured!
      handle_deployment_success(project_item, deployment_uri)
    end
  end

  def handle_deployment_success(project_item, deployment_address)
    Rails.logger.info "Deployment successful for ProjectItem #{project_item.id}"
    project_item.update!(
      status: "Deployment ready at #{deployment_address}",
      status_type: :ready,
      deployment_link: deployment_address
    )
  end

  def handle_deployment_failure(project_item, infrastructure, error_message)
    Rails.logger.error "Deployment failed for ProjectItem #{project_item.id}: #{error_message}"
    infrastructure.mark_failed!(error_message)
    project_item.update!(status: "Deployment failed: #{error_message}. Please contact support.", status_type: :rejected)
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
end
