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
    subscriber = User.new(first_name: "John", last_name: "Doe", email: "john@doe.com",
                          categories: service.categories, research_areas: service.research_areas,
                          categories_updates: true, research_areas_updates: true)
    ServiceMailer.new_service(service, service.categories, service.research_areas, subscriber.email)
  end
end
