# frozen_string_literal: true

class DeployableService::Create < DeployableService::ApplicationService
  def initialize(deployable_service, logo = nil)
    super(deployable_service)
    @logo = logo
  end

  def call
    @deployable_service.update_logo!(@logo) if @logo && @deployable_service.logo.blank?
    @deployable_service.save!

    @deployable_service
  rescue ActiveRecord::RecordNotSaved, ActiveRecord::RecordInvalid => e
    Rails.logger.error "Deployable Service not saved: #{e}"
    @deployable_service
  end
end
