# frozen_string_literal: true

require "rails_helper"


RSpec.feature "Service searching in top bar", js: true do
  include OmniauthHelper

  category = nil

  before { category = create(:category) }

  scenario "search with 'All Services' selected should submit to /services" do
    visit root_path
    click_on(id: "query-submit")

    url = URI.parse(page.current_path)

    expect(url.path).to eq(services_path)

    expect(page).to have_text("All services")
  end

  scenario "search with any category selected should submit to /categories" do
    visit root_path
    select category.name, from: "category-select", visible: false
    click_on(id: "query-submit")

    url = URI.parse(page.current_path)

    expect(url.path).to eq(category_services_path(category_id: category))

    expect(page).to have_text(category.name)
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
    find(:css, "li[id='-option-0']").click
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

    expect(page).to have_text("DDDD Something 1")
    expect(page).to have_text("DDDD Something 2")
    expect(page).to have_text("DDDD Something 3")
  end

  scenario "After starting searching autocomplete not show draft offers", js: true, search: true do
    service = create(:service, title: "DDDD Something 1")
    create(:offer, name: "DDDD Something offer 1", service: service, status: :draft)
    create(:offer, name: "DDDD Something offer 2", service: service, status: :draft)
    create(:service, title: "DDDD Something 2")
    create(:service, title: "DDDD Something 3")
    Offer.reindex

    visit services_path

    fill_in "q", with: "DDDD Something"

    expect(page).to have_text("DDDD Something 1")
    expect(page).to have_text("DDDD Something 2")
    expect(page).to have_text("DDDD Something 3")
    expect(page).to_not have_text("DDDD Something offer 1")
    expect(page).to_not have_text("DDDD Something offer 2")
  end

  scenario "After starting searching autocomplete are shown with published offers", js: true, search: true do
    service = create(:service, title: "DDDD Something 1")
    create(:offer, name: "DDDD Something offer 1", service: service)
    create(:offer, name: "DDDD Something offer 2", service: service)
    create(:service, title: "DDDD Something 2")
    create(:service, title: "DDDD Something 3")
    Offer.reindex

    visit services_path

    fill_in "q", with: "DDDD Something"

    expect(page).to have_text("DDDD Something 1")
    expect(page).to have_text("DDDD Something 2")
    expect(page).to have_text("DDDD Something 3")
    expect(page).to have_text("DDDD Something offer 1")
    expect(page).to have_text("DDDD Something offer 2")
  end
end
