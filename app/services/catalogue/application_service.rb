# frozen_string_literal: true

class Catalogue::ApplicationService < ApplicationService
  def initialize(catalogue)
    super()
    @catalogue = catalogue
  end
end
