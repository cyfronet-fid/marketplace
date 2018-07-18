# frozen_string_literal: true

class Order::RegisterQuestion
  class JIRACommentCreateError < StandardError
    def initialize(question, msg = nil)
      @question = question
      super(msg)
    end
  end

  def initialize(order, question)
    @order = order
    @question = question
  end

  def call
    issue = Jira::Client.new.Issue.find(@order.issue_id)

    comment = issue.comments.build
    if comment.save(body: @question)
      # :TODO: maybe question / order change should be extended to
      # contain jira comment id and status, for easier disaster recovery
      # and tracking
      true
    else
      # :TODO: set errors on @question
      raise JIRACommentCreateError.new(@question)
    end
  end
end
