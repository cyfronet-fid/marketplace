# frozen_string_literal: true

class Service::Create < Service::ApplicationService
  def initialize(service, logo = nil)
    super(service)
    @logo = logo
  end

  def call
    @service.update_logo!(@logo) if @logo && @service.logo.blank?
    @service.save!

    @service
  rescue ActiveRecord::RecordNotSaved, ActiveRecord::RecordInvalid => e
    Rails.logger.error "Service not saved: #{e}"
    @service
  end
end
