# frozen_string_literal: true
class Catalogue::Create < Catalogue::ApplicationService
  def call
    @catalogue.save!
  end
end
