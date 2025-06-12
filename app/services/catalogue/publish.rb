# frozen_string_literal: true

class Catalogue::Publish < Catalogue::ApplicationService
  def call
    @catalogue.update(status: :published)
  end
end
