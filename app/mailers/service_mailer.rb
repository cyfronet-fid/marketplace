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

  def new_service(service, common_categories, common_research_areas, subscriber_email)
    @service = service
    @common_categories = common_categories
    @common_research_areas = common_research_areas
    if @service.logo.attached?
      attachments.inline["logo.png"] = File.read(ActiveStorage::Blob.service.send(:path_for, @service.logo.key))
    end
    interests = []
    interests << ("categories" if @common_categories.present?) <<
        ("research areas" if @common_research_areas.present?)
    subject = "New service in your #{interests.join(" and ")} of interests"
    mail(to: subscriber_email,
         subject: subject,
         template_name: "new_service")
  end
end
