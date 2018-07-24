# frozen_string_literal: true

class Order::Create
  def initialize(order)
    @order = order
  end

  def call
    @order.created!
    @service = Service.find_by(id: @order.service_id)

    if @order.save
      @order.new_change(status: :created, message: "Order created")
      OrderMailer.created(@order).deliver_later

      if !@service.open_access
        Order::RegisterJob.perform_later(@order)
      else
        Order::ReadyJob.perform_later(@order)
      end
    end

    @order
  end
end
