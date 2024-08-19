# frozen_string_literal: true

class Service::Unpublish < Service::ApplicationService
  def call
    public_before = @service.public?
    result = @service.update!(status: :unpublished)
    unbundle_and_notify! if result && public_before
    result
  end
end
