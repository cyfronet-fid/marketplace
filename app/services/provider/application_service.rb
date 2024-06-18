# frozen_string_literal: true

class Provider::ApplicationService < ApplicationService
  def initialize(provider)
    super()
    @provider = provider
  end
end
