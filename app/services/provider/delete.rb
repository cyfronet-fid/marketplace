# frozen_string_literal: true

class Provider::Delete < ApplicationService
  def initialize(provider)
    super()
    @provider = provider.is_a?(Provider) ? provider : Provider.friendly.find(provider)
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
