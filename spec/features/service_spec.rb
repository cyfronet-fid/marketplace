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
    expect(page.body).to have_content service.tagline
  end

end


RSpec.feature "Service filtering and sorting" do
  before(:each) do
    create(:service, title: "AAAA Service", rating: 5.0)
    create(:service, title: "BBBB Service", rating: 3.0)
    create(:service, title: "CCCC Service", rating: 4.0)
    create(:service, title: "DDDD Something 1", rating: 4.1)
    create(:service, title: "DDDD Something 2", rating: 4.0)
    create(:service, title: "DDDD Something 3", rating: 3.9)
    sleep(1)
  end

  scenario "searching in top bar will preserve existing query params", js: true do
    visit services_path(sort: "title")

    fill_in "q", with: "DDDD Something"
    click_on(id: "query-submit")

    expect(page.body.index("DDDD Something 1")).to be < page.body.index("DDDD Something 2")
    expect(page.body.index("DDDD Something 2")).to be < page.body.index("DDDD Something 3")

    expect(page).to have_selector("dl > ul", count: 3)
  end

  scenario "clicking filter button in side bar will preserve existing query params", js: true do
    visit services_path(sort: "title", q: "DDDD Something", utf8: "✓")

    click_on(id: "filter-submit")

    expect(page.body.index("DDDD Something 1")).to be < page.body.index("DDDD Something 2")
    expect(page.body.index("DDDD Something 2")).to be < page.body.index("DDDD Something 3")

    expect(page).to have_selector("dl > ul", count: 3)
  end

  scenario "selecting sorting will set query param and preserve existing ones", js: true do
    visit services_path(q: "DDDD Something", utf8: "✓")

    select "by rate 1-5", from: "sort"

    # For turbolinks to load
    sleep(1)

    expect(page.body.index("DDDD Something 3")).to be < page.body.index("DDDD Something 2")
    expect(page.body.index("DDDD Something 2")).to be < page.body.index("DDDD Something 1")
  end
end
