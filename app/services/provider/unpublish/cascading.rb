# frozen_string_literal: true

class Provider::Unpublish::Cascading < Provider::ApplicationService
  def call
    @provider.status = :unpublished
    result = @provider.save(validate: false)

    if result
      ActiveRecord.after_all_transactions_commit do
        @provider.managed_services.each { |service| UnpublishJob.perform_later(service) if service.published? }
        @provider.reindex
      end
    end

    result
  end
end
