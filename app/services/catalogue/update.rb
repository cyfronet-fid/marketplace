# frozen_string_literal: true

class Catalogue::Update < Catalogue::ApplicationService
  def initialize(catalogue, params)
    super(catalogue)
    @params = params
  end

  def call
    @catalogue.update(@params)
  end
end
