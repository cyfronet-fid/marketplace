# frozen_string_literal: true

class Service::Publish
  def initialize(service)
    @service = service
  end

  def call
    @service.update(status: :published)
  end
end
