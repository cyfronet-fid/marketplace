# frozen_string_literal: true

class Service::Draft
  def initialize(service)
    @service = service
  end

  def call
    @service.update(status: :draft)
    @service.offers.each { |o| Offer::Draft.new(o).call }
  end
end
