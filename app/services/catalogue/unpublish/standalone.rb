# frozen_string_literal: true

class Catalogue::Unpublish::Standalone < Catalogue::ApplicationService
  def call
    @catalogue.update(status: :unpublished)
  end
end
