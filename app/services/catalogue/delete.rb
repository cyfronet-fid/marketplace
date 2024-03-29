# frozen_string_literal: true

class Catalogue::Delete < ApplicationService
  def initialize(catalogue_id)
    super()
    @catalogue = Catalogue.friendly.find(catalogue_id)
  end

  def call
    @catalogue.status = :deleted
    @catalogue.save(validate: false)
  end
end
