# frozen_string_literal: true

class WebhookJiraMailer < ApplicationMailer
  def new_message(message)
    @user = message.messageable.user
    @model = message.messageable
    @message_text = message.message
    @project_name = get_project_name(message.messageable)
    @model_name = message.messageable_type.underscore

    mail(to: @user.email,
                    subject: t("#{@model_name}.mail.new_message", project_name: @project_name).chomp,
                    template_name: "#{@model_name}_new_message")
  end

  def get_project_name(elem)
    elem.has_attribute?("name") ? elem.name : elem.project.name
  end
end
