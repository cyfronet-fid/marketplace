# frozen_string_literal: true

class Ess::Add < ApplicationService
  def initialize(object, type, async: true)
    super()
    @object = object
    @type = type
    @async = async
  end

  def call
    @object.offers.each(&:save) if @object.is_a?(Service) && @object.offers.published&.size&.positive?

    @async ? Ess::UpdateJob.perform_later(payload) : Ess::Update.call(payload)
  end

  private

  def payload
    serializer_type = @object.is_a?(Service) ? "Service" : @object.class.name
    {
      action: "update",
      data_type: @type,
      data: "Ess::#{serializer_type}Serializer".constantize.new(@object).as_json
    }.as_json
  end
end
