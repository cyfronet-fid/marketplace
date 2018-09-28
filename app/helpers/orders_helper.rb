# frozen_string_literal: true

module OrdersHelper
  def status_change(previous, current)
    if current.question?
      "Order owner question"
    elsif previous
      "Order changed from #{previous.status} to #{current.status}"
    else
      "Order #{current.status}"
    end
  end

  def ratingable?
    (@order.ready? && order_ready?(@order) && @order.service_opinion.nil?)
  end

  def order_ready?(order)
    order_change = order.order_changes.where(status: :ready).pluck(:created_at)
    order_change.empty? ? false : (order_change.first < RATE_PERIOD)
  end
end
