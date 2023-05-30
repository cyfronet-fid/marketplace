# frozen_string_literal: true

class Bundle::Ess::Add < ApplicationService
  def initialize(bundle, async: true)
    super()
    @bundle = bundle
    @type = "bundle"
    @async = async
  end

  def call
    @async ? Ess::UpdateJob.perform_later(payload) : Ess::Update.call(payload)
  end

  private

  def payload
    { action: "update", data_type: @type, data: Ess::BundleSerializer.new(@bundle).as_json }.as_json
  end
end
