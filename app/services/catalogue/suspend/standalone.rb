# frozen_string_literal: true

class Catalogue::Suspend::Standalone < Catalogue::ApplicationService
  def call
    @catalogue.update(status: :suspended)
  end
end
