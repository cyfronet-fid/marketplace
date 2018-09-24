# frozen_string_literal: true

class ServiceMailer < ApplicationMailer
  def new_question(recipient_email, service_question, service)
    @service = service
    @message = service_question[:text]
    @author = User.find(service_question[:author])

    mail(to: recipient_email,
         from: @author.email,
         subject: "Question about #{@service.title} service",
         template_name: "new_question")
  end
end
