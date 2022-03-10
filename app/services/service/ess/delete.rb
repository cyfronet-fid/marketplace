# frozen_string_literal: true

class Service::Ess::Delete < ApplicationService
  def initialize(service_id)
    super()
    @service_id = service_id
  end

  def call
    Ess::UpdateJob.perform_later(payload)
  end

  private

  def payload
    { delete: { id: "#{@service_id}" }, commit: {} }.to_json
  end
end
