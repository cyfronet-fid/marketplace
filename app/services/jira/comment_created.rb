# frozen_string_literal: true

class Jira::CommentCreated
  def initialize(project_item, comment)
    @project_item = project_item
    @comment = comment
  end

  def call
    @project_item.new_change(message: body, author: author, iid: id) if body && unique?
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

    def unique?
      !@project_item.order_changes.find_by(iid: id)
    end
end
