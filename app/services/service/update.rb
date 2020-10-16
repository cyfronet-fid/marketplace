# frozen_string_literal: true

class Service::Update
  def initialize(service, params)
    @service = service
    @params = params
  end

  def call
    if @service.offers_count == 1
      url = @params["order_url"] || @params["webpage_url"]
      if url.present? || @params["order_type"]=="order_required"
        @service.offers.first.update(order_type: @params["order_type"],
                                     external: @params["order_url"].present? && @params["order_type"]=="order_required",
                                     webpage: url, status: "published")
      end
    end
    @service.update(@params)
  end
end
