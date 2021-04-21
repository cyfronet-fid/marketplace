# frozen_string_literal: true

class Oms::CallTriggerJob < ApplicationJob
  queue_as :orders

  def perform(oms)
    Oms::CallTrigger.new(oms).call
  end
end
