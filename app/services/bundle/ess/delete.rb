# frozen_string_literal: true

class Bundle::Ess::Delete < ApplicationService
  def initialize(bundle_id)
    super()
    @bundle_id = bundle_id
    @type = "bundle"
  end

  def call
    # TODO: add endpoint to job
    Ess::UpdateJob.perform_later(payload)
  end

  private

  def payload
    # TODO: Must be adequate endpoint
    { action: "delete", data_type: @type, data: { id: @bundle_id } }.as_json
  end
end
