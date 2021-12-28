# frozen_string_literal: true

class Services::InformationDescriptionComponent < ApplicationComponent
  def initialize(order_type:, service_title:, offer:)
    super()
    @order_type = order_type
    @service_title = service_title
    @offer = offer
  end
end
