# frozen_string_literal: true

class ProjectItem::RegisterQuestion
  class JIRACommentCreateError < StandardError
    def initialize(question, msg = nil)
      @question = question
      super(msg)
    end
  end

  delegate :project_item, :message, to: :@question
  attr_reader :question

  def initialize(question)
    @question = question
  end

  def call
    issue = Jira::Client.new.Issue.find(project_item.issue_id)

    comment = issue.comments.build
    if comment.save(body: message)
      question.update(iid: comment.id)
    else
      raise JIRACommentCreateError.new(question)
    end
  end
end
