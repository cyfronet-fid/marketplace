# frozen_string_literal: true

module OrdersHelper
  def status_change(previous, current)
    if previous
      "Order changed from #{previous.status} to #{current.status}"
    else
      "Order #{current.status}"
    end
  end
end
