# frozen_string_literal: true

require "rails_helper"


RSpec.feature "Service searching in top bar", js: true do
  include OmniauthHelper

  category = nil

  before { category = create(:category) }

  scenario "search with 'All' selected should submit to /services" do
    visit root_path
    select "All", from: "category-select"
    click_on(id: "query-submit")

    url = URI.parse(page.current_path)

    expect(url.path).to eq(services_path)

    expect(page).to have_select("category-select", selected: "All")
  end

  scenario "search with any category selected should submit to /categories" do
    visit root_path
    select category.name, from: "category-select"
    click_on(id: "query-submit")

    url = URI.parse(page.current_path)

    expect(url.path).to eq(category_path(category))

    expect(page).to have_select("category-select", selected: category.name)
  end
end
