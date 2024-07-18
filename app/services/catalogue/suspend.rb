# frozen_string_literal: true

class Catalogue::Suspend < Catalogue::ApplicationService
  def call
    @catalogue.status = :suspended
    result = @catalogue.save(validate: false)
    if result
      @catalogue.providers.each { |provider| SuspendJob.perform_later(provider) if provider.published? }
      @catalogue.services.each { |service| SuspendJob.perform_later(service) if service.published? }
    end
    result
  end
end
