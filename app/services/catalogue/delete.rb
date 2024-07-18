# frozen_string_literal: true

class Catalogue::Delete < Catalogue::ApplicationService
  def call
    @catalogue.status = :deleted
    result = @catalogue.save(validate: false)
    if result
      @catalogue.providers.each { |provider| DeleteJob.perform_later(provider) unless provider.deleted? }
      @catalogue.services.each { |service| DeleteJob.perform_later(service) unless service.deleted? }
    end
    result
  end
end
