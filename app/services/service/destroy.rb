# frozen_string_literal: true

class Service::Destroy < Service::ApplicationService
  def call
    @service.destroy
  end
end
