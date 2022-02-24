# frozen_string_literal: true

class Service::Update < ApplicationService
  def initialize(service, params)
    super()
    @service = service
    @params = params
  end

  def call
    public_before = @service.public?
    if @service.errored? && @service.valid?
      result = @service.update(@params.merge(status: :unverified))
    else
      result = @service.update(@params)
    end
    handle_bundles!(public_before) if result
    order_type = @params[:order_type].presence || @service.order_type.presence
    if @service.offers.published.size == 1
      Offer::Update.call(
        @service.offers.first,
        { order_type: order_type, order_url: @params[:order_url] || @service.order_url, status: "published" }
      )
    elsif @service.offers.published.empty?
      Offer::Create.call(
        Offer.new(
          name: "Offer",
          description: "#{@params[:name] || @service.name} Offer",
          order_type: order_type,
          order_url: @params[:order_url] || @service.order_url,
          status: "published",
          service: @service
        )
      )
    end
  end

  private

  def handle_bundles!(public_before)
    notify_bundled_offers! if !public_before && @service.public?
    unbundle_and_notify! if public_before && !@service.public?
  end

  def notify_bundled_offers!
    @service
      .offers
      .published
      .filter(&:bundle?)
      .each do |published_bundle|
        published_bundle.bundled_offers.each do |bundled_offer|
          Offer::Mailer::Bundled.call(bundled_offer, published_bundle)
        end
      end
  end

  def unbundle_and_notify!
    @service
      .offers
      .filter(&:bundled?)
      .each do |bundled_offer|
        bundled_offer.bundle_offers.each do |bundle_offer|
          Offer::Update.call(
            bundle_offer,
            { bundled_offers: bundle_offer.bundled_offers.to_a.reject { |o| o == bundled_offer } }
          )
          Offer::Mailer::Unbundled.call(bundle_offer, bundled_offer)
        end
      end
    @service.reload
  end
end
