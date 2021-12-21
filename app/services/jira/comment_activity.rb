# frozen_string_literal: true

class Jira::CommentActivity
  def initialize(messageable, comment)
    @messageable = messageable
    @comment = comment
  end

  def call
    return if body.blank? || reject?
    message = Message.find_or_initialize_by(messageable: @messageable, iid: id)
    message.update(author_role: :provider, scope: :public, message: body)
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
    owned? || !visible?
  end

  def owned?
    @comment.dig("author", "name") == jira_username
  end

  def visible?
    (@comment.dig("visibility", "value") || "User") == "User"
  end

  def jira_username
    Jira::Client.new.options[:username]
  end
end
