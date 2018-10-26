# frozen_string_literal: true

class Jira::CommentCreated
  def initialize(project_item, comment)
    @project_item = project_item
    @comment = comment
  end

  def call
    return if body.blank? || reject?

    @project_item.new_change(message: body, author: author, iid: id)
  end

  private

    def body
      @comment["body"]
    end

    def id
      @comment["id"]
    end

    def author
      User.find_by(email: @comment["emailAddress"])
    end

    def reject?
      @comment["author"]["name"] == jira_username
    end

    def jira_username
      Jira::Client.new.options[:username]
    end
end
