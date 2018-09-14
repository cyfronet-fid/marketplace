# frozen_string_literal: true

class ActionMailer::MessageDelivery
  def deliver_later(options = {})
    deliver_now
  end
end
