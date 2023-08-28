# frozen_string_literal: true

class Service::Draft < ApplicationService
  def initialize(service)
    super()
    @service = service
  end

  def call
    public_before = @service.public?
    result = @service.update(status: :draft)
    unbundle_and_notify! if result && public_before
    result
  end

  private

  def unbundle_and_notify!
    @service
      .offers
      .map { |o| [o, o.bundles] }
      .each do |offer, bundles|
        bundles.each do |bundle|
          Bundle::Update.call(bundle, { offers: bundle.offers.to_a.reject { |o| o == offer } }, external_update: true)
        end
      end
  end
end
