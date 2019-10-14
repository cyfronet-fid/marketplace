# frozen_string_literal: true

require "rails_helper"


RSpec.feature "Service searching in top bar", js: true do
  include OmniauthHelper

  category = nil

  before { category = create(:category) }

  scenario "search with 'All Services' selected should submit to /services" do
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

  scenario "I can clear search conditions" do
    visit services_path(q: "DDDD Something")
    expect(page).to have_css(".categories", text: "Looking for: DDDD Something")
    find(:css, ".search-clear").click
    expect(page).to_not have_css(".categories", text: "Looking for: DDDD Something")
  end

  scenario "redirect when selecting service_id by autocomplete controller", js: true, search: true do
    service = create(:service)
    fill_in "q", with: service.title
    find(:css, "li.dropdown-item[id='-option-0']").click
    expect(current_path).to eq(service_path(service))
  end

  scenario "redirect when selecting service_id by autocomplete controller", js: true, search: true do
    service = create(:service)
    visit services_path(service_id: service.id)
    expect(current_path).to eq(service_path(service))
  end

  scenario "After starting searching autocomplete are shown", js: true, search: true do
    create(:service, title: "DDDD Something 1")
    create(:service, title: "DDDD Something 2")
    create(:service, title: "DDDD Something 3")

    visit services_path

    fill_in "q", with: "DDDD Something"

    expect(page).to have_selector("li.dropdown-item[role='option']:not([style*=\"display: none\"]", count: 3)
  end
end
