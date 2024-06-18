# frozen_string_literal: true

class Provider::Create < Provider::ApplicationService
  def call
    @provider.save!
  end
end
