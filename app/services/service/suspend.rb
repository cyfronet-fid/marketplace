# frozen_string_literal: true

class Service::Suspend < Service::ApplicationService
  def call
    public_before = @service.public?
    @service.status = :suspended
    result = @service.save(validate: false)
    if result
      unbundle_and_notify! if public_before
      @service.reindex
    end
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
