# frozen_string_literal: true

class Service::Create < Service::ApplicationService
  def initialize(service, logo = nil)
    super(service)
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
        offer_category: @service.service_categories.first || Vocabulary::ServiceCategory.find_by(name: "Other"),
        order_url: @service.order_url,
        internal: @service.order_url.blank?,
        status: "published",
        service_id: @service.id,
        usage_counts_views: @service.usage_counts_views
      )
    Offer::Create.call(new_offer)
    @service
  rescue ActiveRecord::RecordNotSaved, ActiveRecord::RecordInvalid => e
    Rails.logger.error "Service not saved: #{e}"
    @service
  end
end
