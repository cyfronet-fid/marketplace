# frozen_string_literal: true

class Order::ReadyJob < ApplicationJob
  queue_as :orders

  def perform(order)
    Order::Ready.new(order).call
  end
end
