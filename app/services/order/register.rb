# frozen_string_literal: true

class Order::Register
  def initialize(order)
    @order = order
  end

  def call
    register_in_jira! &&
    update_status! &&
    notify!
  end

  private

    def register_in_jira!
      # TODO: Jira integration. This method should throw error on errors which
      #       can be connected with temporary jira issue. Than registration
      #       process will be retired by delayed job.
      true
    end

    def update_status!
      @order.new_change(:registered,
                        "Your order was registered in the order handling system")
      true
    end

    def notify!
      OrderMailer.changed(@order).deliver_later
    end
end
