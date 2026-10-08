# frozen_string_literal: true

class Provider::Unpublish::Standalone < Provider::ApplicationService
  def call
    @provider.update(status: :unpublished)
  end
end
