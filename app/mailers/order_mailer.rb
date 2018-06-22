# frozen_string_literal: true

class OrderMailer < ApplicationMailer
  def created(order)
    @order = order
    @user = order.user

    mail(to: @user.email, subject: "#{prefix(order)} created")
  end

  def changed(order)
    changes = order.order_changes.last(2)

    if changes.size > 1
      @order = order
      @user = order.user
      @current_status = changes.second.status
      @previous_status = changes.first.status

      if @current_status == @previous_status
        new_message(order)
      else
        status_changed(order)
      end
    end
  end

  def new_message(order)
    mail(to: @user,
         subject: "#{prefix(order)} new message",
         template_name: "new_message")
  end

  private

    def status_changed(order)
      mail(to: @user,
            subject: "#{prefix(order)} status changed",
            template_name: "changed")
    end

    def prefix(order)
      "[Order ##{order.id}]"
    end
end
