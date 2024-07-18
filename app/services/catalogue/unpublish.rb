# frozen_string_literal: true

class Catalogue::Unpublish < Catalogue::ApplicationService
  def call
    @catalogue.status = :unpublished
    result = @catalogue.save(validate: false)
    if result
      @catalogue.providers.each { |provider| UnpublishJob.perform_later(provider) if provider.published? }
      @catalogue.services.each { |service| UnpublishJob.perform_later(service) if service.published? }
    end
    result
  end
end
