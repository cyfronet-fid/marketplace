# frozen_string_literal: true

class Catalogue::Delete < ApplicationService
  def initialize(catalogue_id)
    super()
    @catalogue = Catalogue.includes(:providers, :services).friendly.find(catalogue_id)
  end

  def call
    active_organisations = @catalogue.providers.where.not(status: :deleted)
    active_services = @catalogue.services.where.not(status: :deleted)
    if active_organisations.present? || active_services.present?
      false
    else
      @catalogue.status = :deleted
      @catalogue.save(validate: false)
    end
  end
end
