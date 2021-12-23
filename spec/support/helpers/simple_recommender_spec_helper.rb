# frozen_string_literal: true

module SimpleRecommenderSpecHelper
  def populate_database
    categories = create_categories 2
    services = create_services 6

    assign_category_to_services categories[0], services[0..2]
    assign_category_to_services categories[1], services[3..5]

    create_project_with services[0..1]
    create_project_with services[0..2]
    create_project_with services[0..6]

    # below categories and services are ordered by popularity
    [categories, services]
  end

  private

  def create_project_with(services)
    create(
      :project,
      project_items: services.map { |service| create(:project_item, offer: create(:offer, service: service)) }
    )
  end

  def create_categories(size)
    Array.new(size) { create(:category) }
  end

  def create_services(size)
    Array.new(size) { create(:service, categories: []) }
  end

  def assign_category_to_services(category, services)
    services.each { |service| service.categories << category }
  end
end
