# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Service searching in top bar", js: true, end_user_frontend: true do
  include OmniauthHelper

  category = nil

  before { category = create(:category) }

  scenario "search with 'All Services' selected should submit to /services" do
    visit root_path
    click_on(id: "query-submit")

    sleep(1)

    url = URI.parse(page.current_path)

    expect(url.path).to eq(services_path)

    expect(page).to have_text("EOSC Services")
  end

  scenario "search with any category selected should submit to /categories" do
    visit root_path
    select category.name, from: "category-select", visible: false
    click_on(id: "query-submit")

    sleep(1)

    url = URI.parse(page.current_path)

    expect(url.path).to eq(category_services_path(category_id: category))

    expect(page).to have_text(category.name)
  end

  scenario "I can clear search conditions", skip: true do
    visit services_path(q: "DDDD Something")
    expect(page).to have_css(".categories", text: "Looking for: DDDD Something")
    find(:css, ".search-clear").click
    expect(page).to_not have_css(".categories", text: "Looking for: DDDD Something")
  end

  scenario "redirect to service path when selecting service_id by autocomplete controller", js: true, search: true do
    service = create(:service)
    fill_in "q", with: service.name
    expect(page).to have_css("#-option-0")
    find(:css, "li[id='-option-0']").click
    expect(page).to have_content(service.name)
    expect(current_path).to eq(service_path(service))
  end

  scenario "doesn't show unpublished records", js: true, search: true do
    draft_service = create(:service, name: "Awesome 1", status: :draft)
    published_service = create(:service, name: "Awesome 2")
    fill_in "q", with: draft_service.name.truncate(5)

    expect(page).to_not have_content(draft_service.name)
    expect(page).to have_content(published_service.name)
  end

  scenario "redirect to provider path from services path when selecting provider_id by autocomplete controller",
           js: true,
           search: true do
    provider = create(:provider)
    fill_in "q", with: provider.name
    expect(page).to have_css("#-option-0")
    find(:css, "li[id='-option-0']").click
    expect(page).to have_content(provider.name)
    expect(current_path).to eq(provider_path(provider))
  end

  scenario "redirect to service path from services path when selecting service_id by autocomplete controller",
           js: true,
           search: true do
    service = create(:service)
    visit services_path(object_id: service.id, type: "service")
    expect(current_path).to eq(service_path(service))
  end

  scenario "redirect to provider path when selecting provider_id by autocomplete controller", js: true, search: true do
    provider = create(:provider)
    visit services_path(object_id: provider.id, type: "provider")
    expect(current_path).to eq(provider_path(provider))
  end

  scenario "After starting searching autocomplete are shown", js: true, search: true do
    create(:service, name: "DDDD Something 1")
    create(:service, name: "DDDD Something 2")
    create(:service, name: "DDDD Something 3")

    visit services_path

    fill_in "q", with: "DDDD Something"

    expect(page).to have_text("DDDD Something 1")
    expect(page).to have_text("DDDD Something 2")
    expect(page).to have_text("DDDD Something 3")
  end

  scenario "After starting searching autocomplete not show draft offers", js: true, search: true do
    service = create(:service, name: "DDDD Something 1")
    create(:offer, name: "DDDD Something offer 1", service: service, status: :draft)
    create(:offer, name: "DDDD Something offer 2", service: service, status: :draft)
    create(:service, name: "DDDD Something 2")
    create(:service, name: "DDDD Something 3")
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
    service = create(:service, name: "DDDD Something 1")
    create(:offer, name: "DDDD Something offer 1", service: service)
    create(:offer, name: "DDDD Something offer 2", service: service)
    create(:service, name: "DDDD Something 2")
    create(:service, name: "DDDD Something 3")
    Offer.reindex

    visit services_path

    fill_in "q", with: "DDDD Something"

    expect(page).to have_text("DDDD Something 1")
    expect(page).to have_text("DDDD Something 2")
    expect(page).to have_text("DDDD Something 3")
    expect(page).to have_text("DDDD Something offer 1")
    expect(page).to have_text("DDDD Something offer 2")
  end

  scenario "'Other' category should be at the bottom of the category selection box", js: false do
    create(:category, name: "Other")
    create(:category, name: "Research")

    # check services and HOME as there was a bug where home had different list then any other page
    visit root_path
    expect(page).to have_selector("#category-select > option:last-child", text: "Other")
    visit :services
    expect(page).to have_selector("#category-select > option:last-child", text: "Other")
  end

  scenario "After starting searching autocomplete shows provider with resource organisation", js: true, search: true do
    provider = create(:provider, name: "Cyfronet")
    create(:service, name: "DDDD Something 1", resource_organisation: provider)
    create(:service, name: "DDDD Something 2")
    create(:service, name: "DDDD Something 3")

    visit services_path
    fill_in "q", with: "Cyfr"

    expect(page).to have_text("Cyfronet")
    expect(page).to_not have_text("Cyfronet > DDDD Something 1")
    expect(page).to_not have_text("Cyfronet > DDDD Something 2")
    expect(page).to_not have_text("Cyfronet > DDDD Something 3")
  end

  scenario "After starting searching autocomplete shows provider without service", js: true, search: true do
    provider = create(:provider, name: "Cyfronet")
    create(:service, name: "DDDD Something 1", providers: [provider])
    create(:service, name: "DDDD Something 2")
    create(:service, name: "DDDD Something 3")

    visit services_path
    fill_in "q", with: "Cyfr"

    expect(page).to have_text("Cyfronet")
    expect(page).to_not have_text("Cyfronet > DDDD Something 1")
    expect(page).to_not have_text("Cyfronet > DDDD Something 2")
    expect(page).to_not have_text("Cyfronet > DDDD Something 3")
  end

  scenario "Search query respects active filters", js: true, search: true do
    provider = create(:provider, name: "Cyfronet")
    create(:service, name: "abc", resource_organisation: provider)
    create(:service, name: "def", providers: [provider])

    visit services_path(providers: [provider.id])

    fill_in "q", with: "abc"
    click_on(id: "query-submit")

    expect(page).to have_content("Active filters")
    expect(page).to have_content("Providers: #{provider.name}")
    expect(page).to have_current_path("/services?object_id=&type=&anchor=&sort=_score&providers%5B%5D=1&q=abc")
  end

  %i[service provider].each do |type|
    scenario "doesn't show the autocomplete results after clicking an #{type} item", js: true, search: true do
      object = create(type)
      fill_in "q", with: object.name
      expect(page).to have_css("#-option-0")
      find(:css, "li[id='-option-0']").click
      expect(page).to have_selector(".autocomplete-results", visible: false)
    end

    scenario "it preserves the query input after redirect to the #{type} item", js: true, search: true do
      object = create(type)
      fill_in "q", with: object.name
      expect(page).to have_css("#-option-0")
      find(:css, "li[id='-option-0']").click
      expect(page).to have_current_path(send("#{type}_path", object, q: object.name))

      expect(page).to have_selector("#q[value='#{object.name}']")
    end
  end
end
