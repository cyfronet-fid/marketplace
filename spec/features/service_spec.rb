# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Service browsing" do
  include OmniauthHelper

  let(:user) { create(:user) }

  context "as logged in user" do

    before { checkin_sign_in_as(user) }

    scenario "allows to see details" do
      service = create(:service)

      visit service_path(service)

      expect(page.body).to have_content service.title
      expect(page.body).to have_content service.description
      expect(page.body).to have_content service.tagline
    end

    scenario "I see Ask Question" do
      service = create(:service)

      visit service_path(service)

      expect(page).to have_content "Want to ask a question about this service?"

    end

    scenario "I can see question-modal if I click on link", js: true do
      service = create(:service)

      visit service_path(service)

      find("#modal-show").click

      expect(page).to have_css("div#question-modal.show")
    end

    scenario "I can sand message about service", js: true do
      user1, user2 = create_list(:user, 2)
      service = create(:service, contact_emails: [user1.email, user2.email])

      visit service_path(service)

      find("#modal-show").click

      within("#question-modal") do
        fill_in("service_question_text", with: "text")
      end

      expect { click_on "SEND" }.
        to change { ActionMailer::Base.deliveries.count }.by(2)
      expect(page).to have_content("Your message was successfully sended")
    end
  end

  scenario "shows related services" do
    service, related = create_list(:service, 2)
    ServiceRelationship.create!(source: service, target: related)

    visit service_path(service)

    expect(page.body).to have_content "Suggested compatible services"
    expect(page.body).to have_content related.title
  end

  scenario "does not show related services section when no related services" do
    service = create(:service)

    visit service_path(service)

    expect(page.body).to_not have_content "Suggested compatible services"
  end
  context "service has no offers" do
    scenario "service offers section are not displayed" do
      service = create(:service)

      visit service_path(service)

      expect(page.body).not_to have_content("Service offers")
    end
  end

  scenario "show technical parameters in service view" do
    offer = create(:offer, parameters: [{ "id": "id1",
                                          "type": "select",
                                          "label": "Number of CPU Cores",
                                          "config": { "mode": "buttons", "values": [1, 2, 4, 8] },
                                          "value_type": "integer",
                                          "description": "Select number of cores you want" },
                                        { "id": "id2",
                                          "type": "select",
                                          "unit": "GB",
                                          "label": "Amount of RAM per CPU core",
                                          "config": { "mode": "buttons", "values": [1, 2, 4] },
                                          "value_type": "integer",
                                          "description": "Select amount of RAM per core" },
                                        { "id": "id3",
                                          "type": "select",
                                          "unit": "GB",
                                          "label": "Local disk",
                                          "config": { "mode": "buttons", "values": [10, 20, 40] },
                                          "value_type": "integer",
                                          "description": "Amount of local disk space" },
                                        { "id": "id4",
                                          "type": "input",
                                          "label": "Number of VM instances",
                                          "config": { "maximum": 50, "minimum": 1 },
                                          "value_type": "integer",
                                          "description": "Type number of VM instances from 1-50" },
                                        { "id": "id5",
                                          "type": "select",
                                          "label": "Access type",
                                          "config": { "mode": "buttons", "values": ["opportunistic", "reserved"] },
                                          "value_type": "string",
                                          "description": "Choose access type" },
                                        { "id": "id6",
                                          "type": "date",
                                          "label": "Start of service",
                                          "value_type": "string",
                                          "description": "Please choose start date" }])

    checkin_sign_in_as(user)
    puts offer.name
    puts service_path(offer.service)
    visit service_path(offer.service)
    expect(page.body).to have_content("Number of CPU Cores")
    expect(page.body).to have_content("1 - 8")
    expect(page.body).to have_content("Amount of RAM per CPU core")
    expect(page.body).to have_content("1 - 4 GB")
    expect(page.body).to have_content("Local disk")
    expect(page.body).to have_content("10 - 40 GB")
    expect(page.body).to have_content("Number of VM instances")
    expect(page.body).to have_content("10 - 40 GB")
    expect(page.body).to_not have_content("Access type")
    expect(page.body).to_not have_content("Start of service")
  end

  context "as not logged in user" do
    scenario "I need to login to asks service question" do
      service = create(:service)

      visit service_path(service)

      expect(page).to have_content "If you want ask question about service please login!"
    end
  end
end


RSpec.feature "Service filtering and sorting" do
  before(:each) do
    platform = create(:platform, name: "platform 1")
    area = create(:research_area, name: "area 1")
    provider = create(:provider, name: "first provider")
    service = create(:service, title: "AAAA Service", rating: 5.0, dedicated_for: ["VO"])
    service.research_areas << area
    service.providers << provider
    create(:service, title: "BBBB Service", rating: 3.0, dedicated_for: ["Providers"], platforms: [platform])
    create(:service, title: "CCCC Service", rating: 4.0, dedicated_for: ["Researchers"])
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

    expect(page).to have_selector(".media", count: 3)
  end

  scenario "clicking filter button in side bar will preserve existing query params", js: true do
    visit services_path(sort: "title", q: "DDDD Something", utf8: "✓")

    click_on(id: "filter-submit")

    expect(page.body.index("DDDD Something 1")).to be < page.body.index("DDDD Something 2")
    expect(page.body.index("DDDD Something 2")).to be < page.body.index("DDDD Something 3")

    expect(page).to have_selector(".media", count: 3)
  end

  scenario "selecting sorting will set query param and preserve existing ones", js: true do
    visit services_path(q: "DDDD Something", utf8: "✓")

    select "by rate 1-5", from: "sort"

    # For turbolinks to load
    sleep(1)

    expect(page.body.index("DDDD Something 3")).to be < page.body.index("DDDD Something 2")
    expect(page.body.index("DDDD Something 2")).to be < page.body.index("DDDD Something 1")
  end

  scenario "limit number of services per page" do
    create_list(:service, 2)

    visit services_path(per_page: "1")

    expect(page).to have_selector(".media", count: 1)
  end


  scenario "multiselect toggle", js: true do
    visit services_path

    expect(page).to have_selector("input[name='providers[]']:not([style*=\"display: none\"])", count: 5)
    click_on("Show 2 more")
    expect(page).to have_selector("input[name='providers[]']:not([style*=\"display: none\"])", count: 7)
    click_on("Show less")
    expect(page).to have_selector("input[name='providers[]']:not([style*=\"display: none\"])", count: 5)
  end

  scenario "multiselect shows checked element regardless of toggle state", js: true do
    visit services_path

    expect(page).to have_selector("input[name='providers[]']", count: 5)
    click_on("Show 2 more")
    expect(page).to have_selector("input[name='providers[]']", count: 7)
    find(:css, "input[name='providers[]'][value='#{Provider.order(:name).last.id}']").set(true)
    click_on(id: "filter-submit")
    expect(page).to have_selector("input[name='providers[]']", count: 6)
  end

  scenario "multiselect does not show toggle button if everything is shown", js: true do
    visit services_path

    expect(page).to have_selector("input[name='providers[]']", count: 5)
    click_on("Show 2 more")
    find(:css, "input[name='providers[]'][value='#{Provider.joins(:services)
                                                      .order(:name)
                                                      .group("providers.id")
                                                      .order(:name)[-1].id}']").set(true)
    find(:css, "input[name='providers[]'][value='#{Provider.joins(:services)
                                                      .order(:name)
                                                      .group("providers.id")
                                                      .order(:name)[-2].id}']").set(true)
    click_on(id: "filter-submit")

    expect(page).to_not have_selector("#providers > a")
  end

  scenario "toggle button changes number of providers to show", js: true do
    visit services_path
    click_on("Show 2 more")
    find(:css, "input[name='providers[]'][value='#{Provider.order(:name).last.id}']").set(true)
    click_on(id: "filter-submit")

    find("#providers > a", text: "Show 1 more")
  end

  scenario "searching via providers", js: true do
    visit services_path
    find(:css, "input[name='providers[]'][value='#{Provider.order(:name).first.id}']").set(true)
    click_on(id: "filter-submit")

    expect(page).to have_selector(".media", count: 1)
    expect(page).to have_selector("input[name='providers[]']" +
                                      "[value='#{Provider.order(:name).first.id}'][checked='checked']")
  end

  scenario "searching via rating", js: true do
    visit services_path
    select "★★★★★", from: "rating"
    click_on(id: "filter-submit")

    expect(page).to have_selector(".media", count: 1)
  end

  scenario "searching vis research_area" do
    visit services_path
    select ResearchArea.first.name, from: "research_area"
    click_on(id: "filter-submit")

    expect(page).to have_selector(".media", count: 1)
  end

  scenario "searching via dedicated_for", js: true do
    visit services_path
    find(:css, "input[name='dedicated_for[]'][value='VO']").set(true)
    click_on(id: "filter-submit")

    expect(page).to have_selector(".media", count: 1)
    expect(page).to have_selector("input[name='dedicated_for[]'][value='VO'][checked='checked']")
  end

  scenario "searching via platforms", js: true do
    visit services_path
    find(:css, "input[name='related_platforms[]'][value='#{Platform.order(:name).first.id}']").set(true)
    click_on(id: "filter-submit")

    expect(page).to have_selector(".media", count: 1)
  end

  scenario "page query param should be reset after filtering", js: true do
    create_list(:service, 40)
    visit services_path(page: 3)
    find(:css, "input[name='related_platforms[]'][value='#{Platform.order(:name).first.id}']").set(true)
    click_on(id: "filter-submit")

    expect(page.current_path).to_not have_content("page=")
    expect(page).to have_selector(".media", count: 1)
  end


  scenario "searching via location", js: true do
    `pending "add test after implementing location to filtering #{__FILE__}"`
  end
end
