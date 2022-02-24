# frozen_string_literal: true

class Service::Create
  def initialize(service)
    @service = service
  end

  def call
    @service.save
    Offer::Create.call(
      Offer.new(
        name: "Offer",
        description: "#{@service.name} Offer",
        order_type: @service.order_type,
        order_url: @service.order_url,
        internal: @service.order_url.blank?,
        status: "published",
        service: @service
      )
    )
    @service
  end
end
