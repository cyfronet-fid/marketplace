# frozen_string_literal: true

class Provider::Delete
  def initialize(provider_id)
    @provider = Provider.friendly.find(provider_id)
  end

  def call
    active_organisation_service = Service.where(resource_organisation_id: @provider.id).where.not(status: :deleted)
    if active_organisation_service.present?
      false
    else
      @provider.status = :deleted
      updated = @provider.save(validate: false)
      @provider.reindex
      updated
    end
  end
end
