# frozen_string_literal: true

class Message::RegisterMessage
  class JIRACommentCreateError < StandardError
    def initialize(question, msg = nil)
      @question = question
      super(msg)
    end
  end

  delegate :message, :messageable, to: :@question
  attr_reader :question

  def initialize(question)
    @question = question
  end

  def call
    issue = Jira::Client.new.Issue.find(messageable.issue_id)
    comment = issue.comments.build

    raise JIRACommentCreateError, question unless comment.save(body: message)

    question.update(iid: comment.id)
  end
end
