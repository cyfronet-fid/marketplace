# frozen_string_literal: true

class Service::Publish
  def initialize(service, verified: true)
    @service = service
    @status = verified ? :published : :unverified
  end

  def call
    Offer::Publish.new(@service.offers.first).call if @service.offers.size == 1
    @service.update(status: @status)
    Service::Mailer::SendToSubscribers.new(@service).call
  end
end
