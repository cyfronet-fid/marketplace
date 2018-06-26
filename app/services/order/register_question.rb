# frozen_string_literal: true

class Order::RegisterQuestion
  def initialize(order, question)
    @order = order
    @question = question
  end

  def call
    # TODO: Jira integration. This method should throw error on errors which
    #       can be connected with temporary jira issue. Than registration
    #       process will be retired by delayed job.
    puts <<-MSQ
      REGISTER: #{@order.user.full_name} asks question about #{@order}:
        "#{@question}"
    MSQ
  end
end
