# frozen_string_literal: true

class MessageMailer < ApplicationMailer
  def new_message(message, action: nil)
    @user = message.messageable.user
    @model = message.messageable
    @message_text = message.message
    @project_name = get_project_name(message.messageable)
    @model_name = message.messageable_type.underscore
    @action = action

    mail(
      to: @user.email,
      subject:
        t("#{@model_name}#{".#{@action}" if @action.present?}.mail.new_message", project_name: @project_name).chomp,
      template_name: "#{@model_name}#{"_#{@action}" if @action.present?}_new_message"
    )
  end

  def message_edited(message)
    @user = message.messageable.user
    @link = get_link_to_messageable(message)

    mail(to: @user.email, subject: "Message updated", template_name: "message_edited")
  end

  def get_link_to_messageable(message)
    elem = message.messageable
    if message.messageable_type == "Project"
      project_conversation_url(elem)
    else
      project_service_conversation_url(elem.project, elem)
    end
  end

  def get_project_name(elem)
    elem.has_attribute?("name") ? elem.name : elem.project.name
  end
end
