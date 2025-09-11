# frozen_string_literal: true

class DeployableService::CreateDefaultOffer < DeployableService::ApplicationService
  def call
    # Generate JupyterHub-specific parameters
    parameters = DeployableService::JupyterHubParameterGenerator.generate_parameters

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
end
