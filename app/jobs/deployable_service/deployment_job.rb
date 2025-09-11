# frozen_string_literal: true

class DeployableService::DeploymentJob < ApplicationJob
  queue_as :default

  def perform(project_item)
    # Step 1: Fill TOSCA template with user parameters
    filled_template = DeployableService::ToscaTemplateFiller.call(project_item)

    # Step 2: Deploy to Infrastructure Manager
    deployment_address = deploy_to_infrastructure_manager(project_item, filled_template)

    if deployment_address
      # Update project item status - email will be sent automatically via OnStatusTypeUpdated
      project_item.update!(
        status: "Deployment ready at #{deployment_address}",
        status_type: :ready,
        deployment_link: deployment_address
      )
    else
      project_item.update!(status: "Deployment failed - please contact support", status_type: :rejected)
    end
  rescue StandardError => e
    Rails.logger.error "Deployment job failed: #{e.message}"
    project_item.update!(status: "Deployment failed - please contact support", status_type: :rejected)
  end

  private

  def deploy_to_infrastructure_manager(project_item, filled_template)
    Rails.logger.info "Deploying TOSCA template to Infrastructure Manager (#{filled_template.length} characters)"
    Rails.logger.debug "Filled TOSCA Template:\n#{filled_template}"

    # Get user's access token for IM API authentication
    access_token = current_user_token(project_item)

    # Create IM client and deploy infrastructure
    im_client = InfrastructureManager::Client.new(access_token)
    result = im_client.create_infrastructure(filled_template)

    if result[:success]
      infrastructure_id = result[:data]
      Rails.logger.info "Successfully created infrastructure: #{infrastructure_id}"

      # Construct deployment URL from user parameters
      parameters = extract_user_parameters(project_item.properties)
      dns_name = parameters["kube_public_dns_name"] || "jupytermount.vm.fedcloud.eu"
      deployment_url = "https://#{dns_name}/jupyterhub/"

      # Store infrastructure ID for potential future management
      store_infrastructure_metadata(project_item, infrastructure_id, deployment_url)

      deployment_url
    else
      Rails.logger.error "Failed to create infrastructure: #{result[:error]}"
      # Return nil to trigger failure handling
      nil
    end
  rescue StandardError => e
    Rails.logger.error "Infrastructure Manager deployment failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    nil
  end

  def current_user_token(project_item)
    # Get current user's access token (assumes EGI VO)
    user_token = project_item.project.user&.authentication_token
    user_token.presence || ENV.fetch("IM_DEMO_TOKEN", "demo_token_placeholder")
  end

  def extract_user_parameters(properties)
    # ProjectItem.properties can be different formats - handle gracefully
    return {} unless properties.present?

    parameters = {}

    case properties
    when Array
      # Handle array of JSON strings
      properties.each do |prop_json|
        param = prop_json.is_a?(String) ? JSON.parse(prop_json) : prop_json
        parameters[param["id"]] = param["value"] if param["id"] && param["value"]
      rescue JSON::ParserError => e
        Rails.logger.warn "Failed to parse project item property JSON: #{e.message}"
        next
      end
    when Hash
      # Handle direct hash format
      properties.each { |key, value| parameters[key] = value if value.present? }
    else
      Rails.logger.warn "Unexpected properties format: #{properties.class}"
    end

    parameters
  end

  def store_infrastructure_metadata(_project_item, infrastructure_id, deployment_url)
    # Store infrastructure ID and metadata for future management
    Rails.logger.info "Infrastructure metadata - ID: #{infrastructure_id}, URL: #{deployment_url}"

    # In a production system, you might store this in the database:
    # project_item.update!(
    #   infrastructure_id: infrastructure_id,
    #   deployment_metadata: {
    #     infrastructure_id: infrastructure_id,
    #     deployment_url: deployment_url,
    #     created_at: Time.current
    #   }
    # )
  end
end
