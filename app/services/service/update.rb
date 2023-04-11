# frozen_string_literal: true

class Service::Update < ApplicationService
  def initialize(service, params, logo = nil)
    super()
    @service = service
    @params = params
    @logo = logo
  end

  def call
    public_before = @service.public?
    ActiveRecord::Base.transaction do
      if @service.public_contacts.present? && @service.public_contacts.all?(&:marked_for_destruction?)
        @service.public_contacts[0].reload
      end
      @params.merge(status: :unverified) if @service.errored? && @service.valid?

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
    elsif @service.offers.published.empty?
      new_offer =
        Offer.new(
          name: "Offer",
          description: "#{@service.name} Offer",
          service: @service,
          order_type: @service.order_type.presence,
          order_url: @service.order_url,
          status: "published"
        )
      Offer::Create.call(new_offer)
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
      published_bundle.offers.each { |bundled_offer| Offer::Mailer::Bundled.call(published_bundle, bundled_offer) }
    end
  end

  def unbundle_and_notify!
    @service.bundles.each do |bundle|
      bundle.offers.each do |offer|
        Offer::Update.call(
          bundle.main_offer,
          { bundled_connected_offers: bundle.main_offer.bundled_connected_offers.to_a.reject { |o| o == offer } }
        )
        Offer::Mailer::Unbundled.call(bundle, offer)
      end
    end
    @service.reload
  end
end
