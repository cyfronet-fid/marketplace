# frozen_string_literal: true

class OMS::CallTriggerJob < ApplicationJob
  queue_as :orders

  def perform(oms)
    Trigger::Call.new(oms.trigger).call if oms.trigger.present?
  end
end
