# frozen_string_literal: true

class Service::ApplicationService < ApplicationService
  def initialize(service)
    super()
    @service = service
  end

  def unbundle_and_notify!
    @service
      .offers
      .map(&:bundles)
      .flatten
      .uniq
      .each do |bundle|
        Bundle::Update.call(bundle, { offer_ids: (bundle.offer_ids - @service.offer_ids).to_a }, external_update: true)
      end
  end
end
