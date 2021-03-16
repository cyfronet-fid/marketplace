# frozen_string_literal: true

class Service::Update
  def initialize(service, params)
    @service = service
    @params = params
  end

  def call
    if @service.offers.size == 1
      Offer::Update.new(@service.offers.first, { order_type: @params[:order_type] || @service.order_type,
                                   order_url: @params[:order_url] || @service.order_url,
                                   webpage: @params[:webpage_url] || @service.webpage_url,
                                   internal: @params[:webpage_url].blank? && @service.webpage_url.blank?,
                                   status: "published" }).call
    elsif @service.offers.size == 0
      Offer::Create.new(Offer.new(name: "Offer",
                                  description: "#{@params[:name] || @service.name} Offer",
                                  order_type: @params[:order_type] || @service.order_type,
                                  order_url: @params[:order_url] || @service.order_url,
                                  webpage: @params[:webpage_url] || @service.webpage_url,
                                  internal: @params[:webpage_url].blank? && @service.webpage_url.blank?,
                                  status: "published",
                                  service: @service)).call
    end
    if @service.errored? && @service.valid?
      @service.update(@params.merge(status: :unverified))
    else
      @service.update(@params)
    end
  end
end
