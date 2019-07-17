# frozen_string_literal: true

class WebhookJiraMailer < ApplicationMailer
  def new_message(element)
    @user = element.user
    @model = element

    mail(to: @user.email,
         subject: t("#{element.model_name.element}.mail.new_message"),
         template_name: "#{element.model_name.element}_new_message")
  end
end
