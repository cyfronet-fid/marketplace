# frozen_string_literal: true

class Service::Suspend < Service::ApplicationService
  def call
    public_before = @service.public?
    @service.status = :suspended
    result = @service.save(validate: false)
    if result
      unbundle_and_notify! if public_before
      @service.reindex
    end
    result
  end
end
