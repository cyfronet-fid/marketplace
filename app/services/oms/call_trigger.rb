# frozen_string_literal: true

class OMS::CallTrigger
  def initialize(oms)
    @oms = oms
  end

  def call
    Unirest.post @oms.trigger_url if @oms.trigger_url.present?
  end
end
