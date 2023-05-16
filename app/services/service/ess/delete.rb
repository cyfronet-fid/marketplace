# frozen_string_literal: true

class Service::Ess::Delete < ApplicationService
  def initialize(service_id, type)
    super()
    @service_id = service_id
    @type = type == "Datasource" ? "data source" : "service"
  end

  def call
    Offer.where(service_id: @service_id).each { |offer| Offer::Ess::Delete.call(offer.id) }
    Ess::UpdateJob.perform_later(payload)
  end

  private

  def payload
    { action: "delete", data_type: @type, data: { id: @service_id } }.as_json
  end
end
