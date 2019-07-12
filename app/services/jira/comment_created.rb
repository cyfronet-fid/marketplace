# frozen_string_literal: true

class Jira::CommentCreated
  def initialize(messageable, comment)
    @messageable = messageable
    @comment = comment
  end

  def call
    return if body.blank? || reject?
    if @messageable.messages.create(message: body, author: author, iid: id)
      WebhookJiraMailer.new_message(@messageable).deliver_later
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
      @comment["author"]["name"] == jira_username
    end

    def jira_username
      Jira::Client.new.options[:username]
    end
end
