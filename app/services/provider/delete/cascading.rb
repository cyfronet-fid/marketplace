# frozen_string_literal: true

class Provider::Delete::Cascading < Provider::ApplicationService
  # Also accepts a provider id for registry deletes (Provider::DeleteJob).
  # pl/whitelabel's Provider::PcDelete meant to do this but never defined `call`.
  def initialize(provider)
    super(provider.is_a?(Provider) ? provider : Provider.friendly.find(provider))
  end

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
