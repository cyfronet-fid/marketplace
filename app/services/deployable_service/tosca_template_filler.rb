# frozen_string_literal: true

class DeployableService::ToscaTemplateFiller < ApplicationService
  # DNS-related inputs that should not be overridden by users - a unique name is generated instead
  DNS_INPUTS = %w[kube_public_dns_name public_dns_name dns_name].freeze

  def initialize(project_item)
    super()
    @project_item = project_item
    @deployable_service = project_item.offer.deployable_service
    @parameters = extract_user_parameters(@project_item.properties)
  end

  def call
    template_content = DeployableService::FetchTemplate.call(@deployable_service.url)
    fill_template_inputs(template_content, @parameters)
  end

  private

  def extract_user_parameters(properties)
    # ProjectItem.properties can be different formats - handle gracefully
    return {} unless properties.present?

    parameters = {}

    case properties
    when Array
      # Handle array of JSON strings (original assumption)
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

  def fill_template_inputs(template_content, parameters)
    begin
      parsed_template = YAML.safe_load(template_content)
    rescue Psych::SyntaxError => e
      Rails.logger.error "Failed to parse TOSCA template YAML: #{e.message}"
      return template_content # Return original if parsing fails
    end

    # Replace default values in inputs section
    inputs = parsed_template.dig("topology_template", "inputs") || {}

    parameters.each do |param_id, param_value|
      next unless inputs[param_id]
      next if DNS_INPUTS.include?(param_id)

      case param_id
      when "dataset_ids"
        # Split comma-separated DOI list into array
        inputs[param_id]["default"] = param_value.split(",").map(&:strip)
      else
        inputs[param_id]["default"] = param_value
      end
    end

    # Generate unique DNS name for the deployment
    dns_inputs = inputs.slice(*DNS_INPUTS).compact
    if dns_inputs.any?
      generated_dns = generate_unique_dns_name
      dns_inputs.each_value { |input| input["default"] = generated_dns }
      Rails.logger.info "Generated unique DNS for deployment: #{generated_dns}"
    end

    begin
      parsed_template.to_yaml
    rescue StandardError => e
      Rails.logger.error "Failed to convert template back to YAML: #{e.message}"
      template_content # Return original if conversion fails
    end
  end

  def generate_unique_dns_name
    # Generate UUID-based DNS in format: <uuid>.vm.fedcloud.eu
    "#{SecureRandom.uuid}.vm.fedcloud.eu"
  end
end
