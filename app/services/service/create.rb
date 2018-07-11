# frozen_string_literal: true

class Service::Create
  def initialize(service)
    @service = service
  end

  def call
    @service.save

    @service
  end
end
