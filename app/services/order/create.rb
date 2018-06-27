# frozen_string_literal: true

class Order::Create
  def initialize(order)
    @order = order
  end

  def call
    @order.created!

    if @order.save
      @order.new_change(status: :created, message: "Order created")
      OrderMailer.created(@order).deliver_later
      Order::RegisterJob.perform_later(@order)
    end

    @order
  end
end
