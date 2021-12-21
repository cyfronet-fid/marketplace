# frozen_string_literal: true

class Message::RegisterMessageJob < ApplicationJob
  queue_as :orders

  rescue_from(Message::RegisterMessage::JIRACommentCreateError) do |exception|
    # TODO: we need to define what to do when message registration in e.g.
    #       JIRA fails. Maybe we should report this problem to Sentry and
    #       do some manual intervantion?
  end

  rescue_from(StandardError) do |exception|
    # This is general error, which should not occur, but should be
    # caught just in case
  end

  def perform(message)
    Message::RegisterMessage.new(message).call if message.question?
  end
end
