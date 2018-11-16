# frozen_string_literal: true

class ServiceMailer < ApplicationMailer
  def new_question(recipient_email, author, service_question, service)
    @service = service
    @message = service_question[:text]
    @author = author

    mail(to: recipient_email,
         from: @author.email,
         subject: "Question about #{@service.title} service",
         template_name: "new_question")
  end
end
