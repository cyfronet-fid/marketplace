# frozen_string_literal: true

class Order::Create
  def initialize(order)
    @order = order
  end

  def call
    @order.created!

    if @order.save
      @order.new_change(:created, "Order created")
      Order::RegisterJob.perform_later(@order)
    end

    @order
  end
end
