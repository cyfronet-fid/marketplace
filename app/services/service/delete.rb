# frozen_string_literal: true

class Service::Delete < Service::ApplicationService
  def call
    @service.status = :deleted
    result = @service.save!(validate: false)
    if result
      @service.bundles.each { |b| DeleteJob.perform_later(b) }
      @service.offers.each { |o| DeleteJob.perform_later(o) }
      @service.reindex
    end
    result
  end
end
