# frozen_string_literal: true

class Provider::Ess::Delete < ApplicationService
  def initialize(provider_id)
    super()
    @provider_id = provider_id
    @type = "provider"
  end

  def call
    # TODO: add endpoint to job
    Ess::UpdateJob.perform_later(payload)
  end

  private

  def payload
    # TODO: Must be adequate endpoint
    { action: "delete", data_type: @type, data: { id: @provider_id } }.as_json
  end
end
