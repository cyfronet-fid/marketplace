# frozen_string_literal: true

class Provider::Delete < Provider::ApplicationService
  def call
    @provider.status = :deleted
    result = @provider.save(validate: false)
    if result
      @provider.managed_services.each { |service| DeleteJob.perform_later(service) unless service.deleted? }
      @provider.reindex
    end
    result
  end
end
