# frozen_string_literal: true

class Service::Destroy < Service::ApplicationService
  def call
    @service.update(status: :deleted)
  end
end
