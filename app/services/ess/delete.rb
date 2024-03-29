# frozen_string_literal: true

class Ess::Delete < ApplicationService
  def initialize(object_id, type, async: true)
    super()
    @object_id = object_id
    @type = type
    @async = async
  end

  def call
    if @type == ("service" || "datasource")
      Offer.where(service_id: @object_id).each { |offer| Ess::Delete.call(offer.id, offer.class.name) }
    end
    @async ? Ess::UpdateJob.perform_later(payload) : Ess::Update.call(payload)
  end

  private

  def payload
    { action: "delete", data_type: @type, data: { id: @object_id } }.as_json
  end
end
