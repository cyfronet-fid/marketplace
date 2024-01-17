# frozen_string_literal: true

class Service::ApplicationService < ApplicationService
  def initialize(service)
    super()
    @service = service
  end
end
