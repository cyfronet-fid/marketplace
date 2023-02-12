# frozen_string_literal: true

class ServiceMailer < ApplicationMailer
  def new_question(recipient_email, author, email, text, service)
    @service = service
    @message = text
    @author = author
    @email = email

    mail(to: recipient_email, subject: "Question about #{@service.name} service", template_name: "new_question")
  end

  def new_service(service, common_categories, common_scientific_domains, subscriber_email)
    @service = service
    @common_categories = common_categories
    @common_scientific_domains = common_scientific_domains
    if @service.logo.attached? && @service.logo.variable?
      attachments.inline["logo.png"] = File.read(ActiveStorage::Blob.service.send(:path_for, @service.logo.key))
    end
    interests = []
    interests << ("categories" if @common_categories.present?) <<
      ("scientific domains" if @common_scientific_domains.present?)
    subject = "New service in your #{interests.join(" and ")} of interests"
    mail(to: subscriber_email, subject: subject, template_name: "new_service")
  end
end
