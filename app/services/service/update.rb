# frozen_string_literal: true

class Service::Update < Service::ApplicationService
  def initialize(service, params, logo = nil)
    super(service)
    @params = params
    @logo = logo
  end

  def call
    public_before = @service.public?
    ActiveRecord::Base.transaction do
      if @service.public_contacts.present? && @service.public_contacts.all?(&:marked_for_destruction?)
        @service.public_contacts[0].reload
      end
      @service.update_logo!(@logo) if @logo
      @service.update!(@params)
    end

    handle_bundles!(public_before)

    if @service.offers.published.size == 1
      offer_partial = {
        service: @service,
        order_type: @service.order_type.presence,
        order_url: @service.order_url,
        status: "published"
      }
      Offer::Update.call(@service.offers.first, offer_partial)
    end
    true
  rescue ActiveRecord::RecordInvalid
    false
  end

  private

  def handle_bundles!(public_before)
    notify_bundled_offers! if !public_before && @service.public?
    unbundle_and_notify! if public_before && !@service.public?
  end

  def notify_bundled_offers!
    @service.bundles.published.each do |published_bundle|
      published_bundle.offers.each do |bundled_offer|
        Offer::Mailer::Bundled.call(bundled_offer, published_bundle.main_offer)
      end
    end
  end

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
