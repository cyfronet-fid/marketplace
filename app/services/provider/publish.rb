# frozen_string_literal: true

class Provider::Publish < Provider::ApplicationService
  def call
    @provider.update(status: :published)
  end
end
