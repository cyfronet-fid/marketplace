# frozen_string_literal: true

class Service::Destroy
  def initialize(service)
    @service = service
  end

  def call
    @service.destroy
  end
end
