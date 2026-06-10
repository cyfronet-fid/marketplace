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

    # Create offer with auto-generated parameters
    offer =
      Offer.new(
        deployable_service: @deployable_service,
        name: "Deploy #{@deployable_service.name}",
        description: "Deploy #{@deployable_service.name} with JupyterHub and DataMount configuration",
        parameters: parameters,
        status: :published,
        order_type: "order_required", # Can be ordered
        internal: true, # Will trigger deployment API call
        offer_category: compute_category,
        voucherable: false
      )

    if offer.save
      Rails.logger.info "Created default offer for DeployableService " +
                          "'#{@deployable_service.name}' (ID: #{@deployable_service.id})"
      offer
    else
      Rails.logger.error "Failed to create default offer for DeployableService " +
                           "'#{@deployable_service.name}': #{offer.errors.full_messages.join(", ")}"
      nil
    end
  end

  private

  def parameters_from_template_url(url)
    return if url.blank?

    template = fetch_template(raw_github_url(url))
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
  rescue Psych::SyntaxError, URI::InvalidURIError, SocketError, SystemCallError, Net::HTTPError => e
    Rails.logger.error "Failed to fetch default offer parameters from '#{url}': #{e.message}"
    nil
  end

  def fetch_template(url)
    uri = URI.parse(url)
    response = Net::HTTP.get_response(uri)

    return response.body if response.is_a?(Net::HTTPSuccess)

    raise Net::HTTPError.new("HTTP #{response.code} #{response.message}", response)
  end

  def raw_github_url(url)
    url.sub("github.com", "raw.githubusercontent.com").sub("/blob/", "/")
  end

  def parameter_from_tosca_input(id, definition)
    definition = ActiveSupport::HashWithIndifferentAccess.new(definition)
    values = valid_values(definition)
    attrs = {
      id: id,
      name: definition[:label].presence || id.to_s.humanize,
      hint: definition[:description].presence || "TOSCA input #{id}",
      value_type: value_type(definition[:type])
    }

    if values.present?
      Parameter::Select.new(attrs.merge(values: values, mode: "dropdown"))
    else
      Parameter::Input.new(attrs.merge(sensitive: sensitive_input?(id)))
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
