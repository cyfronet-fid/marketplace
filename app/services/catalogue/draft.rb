# frozen_string_literal: true

class Catalogue::Draft < Catalogue::ApplicationService
  def call
    @catalogue.status = :draft
    @catalogue.save(validate: false)
  end
end
