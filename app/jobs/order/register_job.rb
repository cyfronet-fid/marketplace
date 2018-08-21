# frozen_string_literal: true

class Order::RegisterJob < ApplicationJob
  queue_as :orders

  rescue_from(Order::Register::JIRAIssueCreateError) do |exception|
    # TODO: we need to define what to do when question registration in e.g.
    #       JIRA fails. Maybe we should report this problem to Sentry and
    #       do some manual intervantion?
  end

  rescue_from(StandardError) do |exception|
    # This is general error, which should not occur, but should be
    # caught just in case
  end

  def perform(order)
    Order::Register.new(order).call
  end
end
