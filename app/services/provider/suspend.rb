# frozen_string_literal: true

class Provider::Suspend < Provider::ApplicationService
  def call
    @provider.status = :suspended
    result = @provider.save(validate: false)
    if result
      @provider.managed_services.each { |service| SuspendJob.perform_later(service) if service.published? }
      @provider.reindex
    end
    result
  end
end
