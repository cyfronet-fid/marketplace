# frozen_string_literal: true

class Service::Update
  def initialize(service, params)
    @service = service
    @params = params
  end

  def call
    @service.update_attributes(@params)
  end
end
