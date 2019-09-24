# frozen_string_literal: true

class ServiceMailer < ApplicationMailer
  def new_question(recipient_email, author, email, text, service)
    @service = service
    @message = text
    @author = author
    @email = email

    mail(to: recipient_email,
         subject: "Question about #{@service.title} service",
         template_name: "new_question")
  end
end
