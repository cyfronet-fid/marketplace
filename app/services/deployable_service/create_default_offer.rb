# frozen_string_literal: true

class DeployableService::CreateDefaultOffer < DeployableService::ApplicationService
  def call
    # Generate parameters from the referenced TOSCA template.
    parameters = parameters_from_template_url(@deployable_service.url)
    return unless parameters.present?

    # Find the Compute service category
    compute_category = Vocabulary::ServiceCategory.find_by(eid: "service_category-compute")
    unless compute_category
      Rails.logger.error "Could not find 'service_category-compute' for DeployableService offer creation"
      return nil
    end

    offer = default_offer || @deployable_service.offers.build
    new_record = offer.new_record?
    offer.assign_attributes(
      name: "Deploy #{@deployable_service.name}",
      description: "Deploy #{@deployable_service.name}",
      parameters: parameters,
      status: :published,
      order_type: "order_required", # Can be ordered
      internal: true, # Will trigger deployment API call
      default: true,
      offer_category: compute_category,
      voucherable: false
    )

    if offer.save
      Rails.logger.info "#{new_record ? "Created" : "Updated"} default offer for DeployableService " +
                          "'#{@deployable_service.name}' (ID: #{@deployable_service.id})"
      offer
    else
      Rails.logger.error "Failed to #{new_record ? "create" : "update"} default offer for DeployableService " +
                           "'#{@deployable_service.name}': #{offer.errors.full_messages.join(", ")}"
      nil
    end
  end

  private

  def default_offer
    @deployable_service.offers.find_by(default: true) ||
      @deployable_service.offers.find_by(internal: true, order_type: "order_required")
  end

  def parameters_from_template_url(url)
    return if url.blank?

    template = DeployableService::FetchTemplate.call(url)
    parsed = YAML.safe_load(template)
    unless parsed.is_a?(Hash)
      Rails.logger.error("Failed to fetch default offer parameters from '#{url}': response is not a YAML mapping")
      return
    end

    inputs = parsed.dig("topology_template", "inputs")
    unless inputs.present?
      Rails.logger.error("Failed to fetch default offer parameters from '#{url}': topology_template.inputs missing")
      return
    end

    inputs.map { |id, definition| parameter_from_tosca_input(id, definition || {}) }
  rescue Psych::SyntaxError, URI::InvalidURIError, SocketError, SystemCallError, Faraday::Error => e
    Rails.logger.error "Failed to fetch default offer parameters from '#{url}': #{e.message}"
    nil
  end

  def parameter_from_tosca_input(id, definition)
    definition = ActiveSupport::HashWithIndifferentAccess.new(definition)
    values = valid_values(definition)
    default = default_value(id, definition)
    attrs = {
      id: id,
      name: definition[:label].presence || id.to_s.humanize,
      hint: definition[:description].presence || "TOSCA input #{id}",
      value_type: value_type(definition[:type])
    }

    if values.present?
      Parameter::Select.new(
        attrs.merge(values: values, mode: "dropdown", default_value: (default if values.include?(default)))
      )
    else
      sensitive = sensitive_input?(id)
      Parameter::Input.new(attrs.merge(sensitive: sensitive, default_value: (default unless sensitive)))
    end
  end

  # Only string, scalar-unit and integer defaults are pre-filled: submitted values overwrite the template default,
  # so pre-filling other TOSCA types (boolean, list, ...) would change them into strings.
  def default_value(id, definition)
    # Each order gets its own DNS name (see ProjectItem::Attributes), so none is stored with the offer
    return if DeployableService::DnsName.input?(id)

    default = definition[:default]
    case definition[:type].to_s
    when "integer"
      Integer(default.to_s, exception: false)
    when "string"
      default.to_s if default.is_a?(String) || default.is_a?(Numeric)
    when /\Ascalar-unit\./
      default if default.is_a?(String)
    end
  end

  def valid_values(definition)
    Array(definition[:constraints])
      .filter_map { |constraint| constraint["valid_values"] || constraint[:valid_values] }
      .first
  end

  def value_type(tosca_type)
    tosca_type.to_s == "integer" ? "integer" : "string"
  end

  def sensitive_input?(id)
    id.to_s.match?(/password|secret|token/i)
  end
end
