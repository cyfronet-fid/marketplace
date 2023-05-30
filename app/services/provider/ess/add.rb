# frozen_string_literal: true

class Provider::Ess::Add < ApplicationService
  def initialize(provider, async: true)
    super()
    @provider = provider # TODO: Change payload to the new format here
    @type = "provider"
    @async = async
  end

  def call
    @async ? Ess::UpdateJob.perform_later(payload) : Ess::Update.call(payload)
  end

  private

  def payload
    { action: "update", data_type: @type, data: Ess::ProviderSerializer.new(@provider).as_json }.as_json
  end
end
