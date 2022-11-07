# frozen_string_literal: true

class Datasource::Delete
  def initialize(datasource_id)
    @datasource = Datasource.friendly.find(datasource_id)
  end

  def call
    active_organisation_service = Datasource.where(resource_organisation_id: @datasource.id).where.not(status: :deleted)
    if active_organisation_service.present?
      false
    else
      @datasource.status = :deleted
      updated = @datasource.save(validate: false)
      @datasource.reindex
      updated
    end
  end
end
