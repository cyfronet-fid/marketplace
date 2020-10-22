# frozen_string_literal: true

class Service::Publish
  def initialize(service, verified: true)
    @service = service
    @status = verified ? :published : :unverified
  end

  def call
    if @service.offers.size == 1
      Offer::Publish.new(@service.offers.first).call
    end
    @service.update(status: @status)
    Service::Mailer::SendToSubscribers.new(@service).call
  end
end
