# frozen_string_literal: true

class ProviderMailer < ApplicationMailer
  def new_question(recipient_email, author, email, text, provider)
    @provider = provider
    @message = text
    @author = author
    @email = email

    mail(to: recipient_email, subject: "Question about #{@provider.name}", template_name: "new_question")
  end

  # ONB-01
  def waiting_for_approval(approval_request)
    @provider = approval_request.approvable
    @user = approval_request.user

    mail(to: @user.email, subject: "New provider - #{@provider.name} is waiting for approval")
  end

  # ONB-02
  def approved(provider, recipient_email)
    @provider = provider

    mail(to: recipient_email, subject: "Provider - #{@provider.name} is approved")
  end

  # ONB-03
  def rejected(provider, recipient_email)
    @provider = provider
    @helpdesk_email = Mp::Application.config.helpdesk_email

    mail(to: recipient_email, reply_to: @helpdesk_email, subject: "Provider - #{@provider.name} was not approved")
  end

  # ONB-04
  def changes_requested(message, recipient_email)
    @provider = message.messageable.approvable
    @message_text = message.message
    @helpdesk_email = Mp::Application.config.helpdesk_email

    mail(to: recipient_email, reply_to: @helpdesk_email, subject: "Provider - #{@provider.name} needs more information")
  end
end
