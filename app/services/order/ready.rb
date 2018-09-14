# frozen_string_literal: true

class Order::Ready
  def initialize(order)
    @order = order
  end

  def call
    update_status! &&
    notify!
  end

  private

    def update_status!
      @order.new_change(status: :ready,
                        message: "Your order is ready")
    end

    def notify!
      OrderMailer.changed(@order).deliver_later
      OrderMailer.rate_service(@order).deliver_later(wait_until: RATE_AFTER_PERIOD.from_now)
    end
end
