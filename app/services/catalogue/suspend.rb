# frozen_string_literal: true

class Catalogue::Suspend < Catalogue::ApplicationService
  def call
    @catalogue.update(status: :suspended)
  end
end
