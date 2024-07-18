# frozen_string_literal: true

class Provider::Unpublish < Provider::ApplicationService
  def call
    @provider.status = :unpublished
    result = @provider.save(validate: false)
    if result
      @provider.managed_services.each { |service| UnpublishJob.perform_later(service) if service.published? }
      @provider.reindex
    end
    result
  end
end
