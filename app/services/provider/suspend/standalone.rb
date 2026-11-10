# frozen_string_literal: true

class Provider::Suspend::Standalone < Provider::ApplicationService
  def call
    @provider.update!(status: :suspended)
  end
end
