# frozen_string_literal: true

class Provider::Update < Provider::ApplicationService
  def initialize(provider, params)
    super(provider)
    @params = params
  end

  def call
    @provider.update(@params)
  end
end
