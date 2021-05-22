# frozen_string_literal: true

class Service::Draft
  def initialize(service)
    @service = service
  end

  def call
    @service.update(status: :draft)
  end
end
