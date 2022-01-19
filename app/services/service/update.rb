# frozen_string_literal: true

class Service::Update
  def initialize(service, params)
    @service = service
    @params = params
  end

  def call
    if @service.errored? && @service.valid?
      @service.update(@params.merge(status: :unverified))
    else
      @service.update(@params)
    end
    order_type = @params[:order_type].presence || @service.order_type.presence
    if @service.offers.published.size == 1
      Offer::Update.new(
        @service.offers.first,
        { order_type: order_type, order_url: @params[:order_url] || @service.order_url, status: "published" }
      ).call
    elsif @service.offers.published.empty?
      Offer::Create.new(
        Offer.new(
          name: "Offer",
          description: "#{@params[:name] || @service.name} Offer",
          order_type: order_type,
          order_url: @params[:order_url] || @service.order_url,
          status: "published",
          service: @service
        )
      ).call
    end
  end
end
