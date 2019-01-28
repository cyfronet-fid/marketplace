# frozen_string_literal: true

require "rails_helper"


RSpec.feature "Service searching in top bar", js: true do
  include OmniauthHelper

  category = nil

  before { category = create(:category) }

  scenario "search with 'Allservices' selected should submit to /services" do
    visit root_path
    select "All services", from: "category-select"
    click_on(id: "query-submit")

    url = URI.parse(page.current_path)

    expect(url.path).to eq(services_path)

    expect(page).to have_select("category-select", selected: "All services")
  end

  scenario "search with any category selected should submit to /categories" do
    visit root_path
    select category.name, from: "category-select"
    click_on(id: "query-submit")

    url = URI.parse(page.current_path)

    expect(url.path).to eq(category_services_path(category_id: category))

    expect(page).to have_select("category-select", selected: category.name)
  end
end
