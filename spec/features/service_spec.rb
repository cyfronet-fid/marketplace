# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Service browsing" do
  include OmniauthHelper

  let(:user) { create(:user) }

  before { checkin_sign_in_as(user) }

  scenario "allows to see details" do
    service = create(:service)

    visit service_path(service)

    expect(page.body).to have_content service.title
    expect(page.body).to have_content service.description
    expect(page.body).to have_content service.terms_of_use
    expect(page.body).to have_content service.tagline
  end

  scenario "terms of use is rendered from markdown to html" do
    service = create(:service, terms_of_use: "# Terms of use h1")

    visit service_path(service)

    expect(page.body).to match(/<h1>Terms of use h1/)
  end
end


RSpec.feature "Service filtering and sorting" do
  before { Capybara.current_driver = Capybara.javascript_driver }

  after { Capybara.current_driver = :rack_test }

  scenario "searching in top bar will preserve existing query params" do
    visit services_path(sort: "title")

    fill_in "q", with: "abc"
    click_on(id: "query-submit")

    expect(page).to have_current_path(services_path + "?utf8=✓&q=abc&sort=title")
  end

  scenario "clicking filter button in side bar will preserve existing query params" do
    visit services_path(sort: "title", q: "abc", utf8: "✓")

    click_on(id: "filter-submit")

    expect(page).to have_current_path(services_path(sort: "title", q: "abc", utf8: "✓"))
  end

  scenario "selecting sorting will set query param and preserve existing ones" do
    visit services_path(q: "abc", utf8: "✓")

    select "by rate 1-5", from: "sort"

    expect(page).to have_current_path(services_path + "?q=abc&utf8=✓&sort=rating")
  end
end
