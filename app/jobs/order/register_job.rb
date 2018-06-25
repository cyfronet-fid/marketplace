# frozen_string_literal: true

class Order::RegisterJob < ApplicationJob
  queue_as :orders

  def perform(order)
    Order::Register.new(order).call
  end
end
