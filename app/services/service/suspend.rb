# frozen_string_literal: true

class Service::Suspend < Service::ApplicationService
  def call
    public_before = @service.public?
    result = @service.update!(status: :suspended)
    unbundle_and_notify! if result && public_before
    result
  end
end
