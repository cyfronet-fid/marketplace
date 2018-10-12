# frozen_string_literal: true

class Order::RegisterQuestionJob < ApplicationJob
  queue_as :orders

  rescue_from(Order::RegisterQuestion::JIRACommentCreateError) do |exception|
    # TODO: we need to define what to do when question registration in e.g.
    #       JIRA fails. Maybe we should report this problem to Sentry and
    #       do some manual intervantion?
  end

  rescue_from(StandardError) do |exception|
    # This is general error, which should not occur, but should be
    # caught just in case
  end

  def perform(question)
    if question.question?
      Order::RegisterQuestion.new(question).call
    end
  end
end
