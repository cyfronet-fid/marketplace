# frozen_string_literal: true

# Values of the TOSCA template inputs submitted with the order, sent to ADM with the deployment.
# Only inputs declared in the template are kept, and DNS inputs get a unique generated name.
class DeployableService::DeploymentInputs < ApplicationService
  def initialize(project_item, template)
    super()
    @project_item = project_item
    @template = template
  end

  def call
    declared = @template.inputs.keys
    inputs = parameters.slice(*declared).reject { |id, _| DeployableService::DnsName.input?(id) }
    inputs["dataset_ids"] = inputs["dataset_ids"].split(",").map(&:strip) if inputs["dataset_ids"].is_a?(String)

    dns_inputs = declared & DeployableService::DnsName::INPUTS
    if dns_inputs.any?
      dns_name = dns_name_from(parameters)
      dns_inputs.each { |id| inputs[id] = dns_name }
      Rails.logger.info "Unique DNS for deployment: #{dns_name}"
    end

    inputs
  end

  private

  # ProjectItem.properties can be different formats - handle gracefully
  def parameters
    @parameters ||=
      case (properties = @project_item.properties)
      when Array
        properties.filter_map { |property| parse_property(property) }.to_h
      when Hash
        properties.compact_blank
      else
        {}
      end
  end

  def parse_property(property)
    param = property.is_a?(String) ? JSON.parse(property) : property
    [param["id"], param["value"]] if param["id"] && param["value"]
  rescue JSON::ParserError => e
    Rails.logger.warn "Failed to parse project item property JSON: #{e.message}"
    nil
  end

  def dns_name_from(parameters)
    submitted = parameters.values_at(*DeployableService::DnsName::INPUTS)
    submitted.find { |value| DeployableService::DnsName.generated?(value) && !dns_name_taken?(value) } ||
      DeployableService::DnsName.generate
  end

  # A generated name could still be copied from another order (e.g. from its deployment link)
  def dns_name_taken?(dns_name)
    ProjectItem.where.not(id: @project_item.id).exists?(["properties @> ?", [value: dns_name].to_json])
  end
end
