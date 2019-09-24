# frozen_string_literal: true

class ServiceMailer < ApplicationMailer
  def new_question(recipient_email, question, service)
    @service = service
    @message = question.text
    @author = question.author
    @email = question.email

    mail(to: recipient_email,
         subject: "Question about #{@service.title} service",
         template_name: "new_question")
  end
end
