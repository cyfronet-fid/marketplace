# frozen_string_literal: true

class Service::Create < ApplicationService
  def initialize(service, logo = nil)
    super()
    @service = service
    @logo = logo
  end

  def call
    @service.update_logo!(@logo) if @logo && @service.logo.blank?
    @service.save!

    new_offer =
      Offer.new(
        name: "Offer",
        description: "#{@service.name} Offer",
        order_type: @service.order_type,
        order_url: @service.order_url,
        internal: @service.order_url.blank?,
        status: "published",
        service: @service
      )
    Offer::Create.call(new_offer)
    @service
  rescue ActiveRecord::RecordNotSaved, ActiveRecord::RecordInvalid => e
    Rails.logger.error "Service not saved: #{e}"
    @service
  end
end
