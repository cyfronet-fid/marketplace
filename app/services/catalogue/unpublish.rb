# frozen_string_literal: true

class Catalogue::Unpublish < Catalogue::ApplicationService
  def call
    @catalogue.update(status: :unpublished)
  end
end
