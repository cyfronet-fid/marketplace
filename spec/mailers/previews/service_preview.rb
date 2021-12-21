# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/service
#
# !!! We are using last created project_item to show email previews !!!
class ServicePreview < ActionMailer::Preview
  def new_question
    user = User.last
    ServiceMailer.new_question("john@doe.com", user.full_name, user.email, "TEST", Service.last)
  end

  def new_service
    service = Service.first
    subscriber =
      User.new(
        first_name: "John",
        last_name: "Doe",
        email: "john@doe.com",
        categories: service.categories,
        scientific_domains: service.scientific_domains,
        categories_updates: true,
        scientific_domains_updates: true
      )
    ServiceMailer.new_service(service, service.categories, service.scientific_domains, subscriber.email)
  end
end
