# frozen_string_literal: true

class Jira::CommentCreated
  def initialize(messageable, comment)
    @messageable = messageable
    @comment = comment
  end

  def call
    return if body.blank? || reject?
    message = @messageable.messages.create(message: body, author: author, iid: id)

    if message.persisted?
      WebhookJiraMailer.new_message(message).deliver_later
    end
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
