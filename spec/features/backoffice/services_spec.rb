# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Services in backoffice" do
  include OmniauthHelper

  context "As a service portolio manager" do
    let(:user) { create(:user, roles: [:service_portfolio_manager]) }

    before { checkin_sign_in_as(user) }

    scenario "I can see all services" do
      create(:service, title: "service1")
      create(:service, title: "service2")

      visit backoffice_services_path

      expect(page).to have_content("service1")
      expect(page).to have_content("service2")
    end

    scenario "I can see any service" do
      service = create(:service, title: "service1")

      visit backoffice_service_path(service)

      expect(page).to have_content("service1")
    end

    scenario "I can create new service", js: true do
      category = create(:category)
      provider = create(:provider)
      research_area = create(:research_area)
      platform = create(:platform)
      target_group = create(:target_group)

      visit backoffice_services_path
      click_on "Create new service"

      fill_in "Title", with: "service title"
      fill_in "Description", with: "service description"
      fill_in "Terms of use", with: "service terms of use"
      fill_in "Tagline", with: "service tagline"
      fill_in "Service website", with: "https://sample.url"
      fill_in "Places", with: "Europe"
      fill_in "Languages", with: "English"
      select target_group.name, from: "Dedicated For"
      fill_in "Terms of use url", with: "https://sample.url"
      fill_in "Access policies url", with: "https://sample.url"
      fill_in "Corporate sla url", with: "https://sample.url"
      fill_in "Webpage url", with: "https://sample.url"
      fill_in "Manual url", with: "https://sample.url"
      fill_in "Helpdesk url", with: "https://sample.url"
      fill_in "Tutorial url", with: "https://sample.url"
      fill_in "Restrictions", with: "Reaserch affiliation needed"
      fill_in "Phase", with: "Production"
      fill_in "Activate message", with: "Welcome!!!"
      select research_area.name, from: "Research areas"
      select provider.name, from: "Providers"
      select "open_access", from: "Service type"
      select platform.name, from: "Platforms"
      fill_in "service_contact_emails_0", with: "person1@test.ok"
      page.find("#add-email-field").click
      fill_in "service_contact_emails_1", with: "person2@test.ok"
      select category.name, from: "Categories"
      select user, from: "Owners"

      fill_in "service_sources_attributes_0_eid", with: "12345"

      expect { click_on "Create Service" }.
        to change { user.owned_services.count }.by(1)


      expect(page).to have_content("service title")
      expect(page).to have_content("service description")
      expect(page).to have_content("service terms of use")
      expect(page).to have_content("service tagline")
      expect(page).to have_content("https://sample.url")
      expect(page).to have_content("open_access")
      expect(page).to have_content("person1@test.ok")
      expect(page).to have_content("person2@test.ok")
      expect(page).to have_content("Welcome!!!")
      expect(page).to have_content(research_area.name)
      expect(page).to have_content(target_group.name)
      expect(page).to have_content(category.name)
      expect(page).to have_content("Publish")
      expect(page).to have_content("eic: 12345")
    end

    scenario "I can edit any service" do
      service = create(:service, title: "my service")

      visit backoffice_service_path(service)
      click_on "Edit"

      fill_in "Title", with: "updated title"
      click_on "Update Service"

      expect(page).to have_content("updated title")
    end

    scenario "I can add new offer" do
      service = create(:service, title: "my service", owners: [user])

      visit backoffice_service_path(service)
      click_on "Add new offer"

      expect {
        fill_in "Name", with: "new offer"
        fill_in "Description", with: "test offer"
        click_on "Create Offer"
      }.to change { service.offers.count }.by(1)

      expect(service.offers.last.name).to eq("new offer")
    end

    scenario "I can edit offer" do
      service = create(:service, title: "my service", status: :draft)
      offer = create(:offer, name: "offer1", description: "desc", service: service)

      visit backoffice_service_path(service)
      click_on(class: "edit-offer")

      fill_in "Description", with: "new desc"
      click_on "Update Offer"

      expect(page).to have_content("new desc")
      expect(offer.reload.description).to eq("new desc")
    end

    scenario "I can delete offer" do
      service = create(:service, title: "my service", status: :draft)
      offer = create(:offer, name: "offer1", description: "desc", service: service)

      visit backoffice_service_path(service)
      click_on(class: "delete-offer")

      expect(page).to have_content("This service has no offers")
    end

    scenario "I can delete offer" do
      service = create(:service, title: "my service")

      visit backoffice_service_path(service)
      expect(page).to have_content("This service has no offers")
    end

    scenario "I can change service status from publish to draft" do
      service = create(:service, title: "my service")

      visit backoffice_service_path(service)
      click_on("Stop showing in the MP")

      expect(page).to have_selector(:link_or_button, "Publish")
    end

    scenario "I can change external id of the service" do
      service = create(:service, title: "my service")
      external_source = create(:service_source, eid: 777, source_type: "eic", service: service)

      visit backoffice_service_path(service)
      click_on "Edit"

      expect(page).to have_content("777")
      fill_in "service_sources_attributes_0_eid", with: "12345"
      click_on "Update Service"
      expect(page).to have_content("eic: 12345")
    end

    scenario "I can change upstream" do
      service = create(:service, title: "my service")
      external_source = create(:service_source, service: service)

      visit backoffice_service_path(service)
      click_on "Edit"

      select external_source.to_s, from: "Service Upstream"
      click_on "Update Service"
      expect(page).to have_content(external_source.to_s, count: 2)
    end
  end
end
