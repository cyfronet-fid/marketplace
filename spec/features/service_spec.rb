# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Service browsing" do
  include OmniauthHelper

  scenario "allows to see service details" do
    service = create(:service, tag_list: ["my-tag"])

    visit service_path(service)

    expect(body).to have_content service.title
    expect(body).to have_content service.description
    expect(body).to have_content service.tagline
    expect(body).to have_content "my-tag"
  end

  scenario "not allows to see draft service via direct link for default user" do
    service = create(:service, status: :draft)
    visit service_path(service)

    expect(page).to have_content("This service is not published in the Marketplace yet, " +
    "therefore it cannot be accessed. If you are the Service Owner or Service Portfolio Manager and wish " +
    "to manage this service, please log in and go to the Backoffice tab.")
    expect(current_path).to eq(root_path)
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

  scenario "offers section is not shown when service does not have offers" do
    service = create(:service)

    visit service_path(service)

    expect(page.body).not_to have_content("Service offers")
  end

  scenario "I cannot see offers section when only one is published" do
    service = create(:service)
    offer1 = create(:offer, status: :draft, service: service)
    offer2 = create(:offer, service: service)

    visit service_path(service)

    expect(page).to have_link("Order")
    expect(page).to_not have_content(offer2.name)
    expect(page).to_not have_content(offer1.name)
  end

  scenario "Offer are converted from markdown to html" do
    offer = create(:offer, description: "# Test offer\r\n\rDescription offer")

    visit service_path(offer.service)

    find(".card-body h1", text: "Test offer")
    find(".card-body p", text: "Description offer")
  end

  scenario "Unpublished offers are not showed" do
    offer = create(:offer, name: "unpublished offer", status: :draft)

    visit service_path(offer.service)

    expect(page).not_to have_content("unpublished offer")
  end

  scenario "show technical parameters" do
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
                                          "type": "range",
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

  scenario "I cannot order serice if there is no published offer" do
    offer = create(:offer, status: :draft)

    visit service_path(offer.service)

    expect(page).to_not have_link("Order")
  end

  scenario "should have 'All' link in categories with all services count" do
    visit services_path

    expect(page).to have_text("All Services #{Service.count}")
  end

  scenario "should by default sort services by name, ascending" do
    create(:service, title: "Service c")
    create(:service, title: "Service b")
    create(:service, title: "Service a")

    visit services_path

    expect(page.body.index("Service a")).to be < page.body.index("Service b")
    expect(page.body.index("Service b")).to be < page.body.index("Service c")
  end

  scenario "sorting will set query param and preserve existing ones", js: true do
    create(:service, title: "DDDD Something 1", rating: 4.1)
    create(:service, title: "DDDD Something 2", rating: 4.0)
    create(:service, title: "DDDD Something 3", rating: 3.9)

    visit services_path(q: "DDDD Something", sort: "rating")

    expect(page.text.index("DDDD Something 3")).to be < page.text.index("DDDD Something 2")
    expect(page.text.index("DDDD Something 2")).to be < page.text.index("DDDD Something 1")
  end

  scenario "limit number of services per page" do
    create(:service, title: "Service a")
    create(:service, title: "Service b")

    visit services_path(per_page: "1")

    expect(page).to have_text("Service a")
    expect(page).to_not have_text("Service b")
  end
end
