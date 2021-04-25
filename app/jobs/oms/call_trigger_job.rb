# frozen_string_literal: true

class OMS::CallTriggerJob < ApplicationJob
  queue_as :orders

  def perform(oms)
    OMS::CallTrigger.new(oms).call
  end
end
