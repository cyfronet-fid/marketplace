# frozen_string_literal: true

class Jira::CommentCreated
  def initialize(order, comment)
    @order = order
    @comment = comment
  end

  def call
    @order.new_change(message: body, author: author, iid: id) if body && unique?
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
      !@order.order_changes.find_by(iid: id)
    end
end
