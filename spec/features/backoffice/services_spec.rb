# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Services in backoffice" do
  include OmniauthHelper

  context "As a service portolio manager" do
    let(:user) { create(:user, roles: [:service_portfolio_manager]) }

    before { checkin_sign_in_as(user) }

    scenario "I can see all services" do
      create(:service, name: "service1")
      create(:service, name: "service2")

      visit backoffice_services_path

      expect(page).to have_content("service1")
      expect(page).to have_content("service2")
    end

    scenario "I can see any service" do
      service = create(:service, name: "service1")

      visit backoffice_service_path(service)

      expect(page).to have_content("service1")
    end

    scenario "I can create new service" do
      category = create(:category)
      provider = create(:provider)
      scientific_domain = create(:scientific_domain)
      platform = create(:platform)
      target_group = create(:target_group)

      visit backoffice_services_path
      click_on "Create new Service"

      fill_in "Name", with: "service name"
      fill_in "Description", with: "service description"
      fill_in "Terms of use", with: "service terms of use"
      fill_in "Tagline", with: "service tagline"
      fill_in "Places", with: "Europe"
      fill_in "Languages", with: "English"
      select target_group.name, from: "Dedicated For"
      fill_in "Terms of use url", with: "https://sample.url"
      fill_in "Access policies url", with: "https://sample.url"
      fill_in "Sla url", with: "https://sample.url"
      fill_in "Webpage url", with: "https://sample.url"
      fill_in "Manual url", with: "https://sample.url"
      fill_in "Helpdesk url", with: "https://sample.url"
      fill_in "Training information url", with: "https://sample.url"
      fill_in "Restrictions", with: "Reaserch affiliation needed"
      fill_in "Activate message", with: "Welcome!!!"
      fill_in "Service Order Target", with: "email@domain.com"
      select "Alpha (min. TRL 5)", from: "Phase"
      select scientific_domain.name, from: "Scientific domains"
      select provider.name, from: "Providers"
      select "open_access", from: "Order type"
      select platform.name, from: "Platforms"
      fill_in "service_contact_emails_0", with: "person1@test.ok"
      # page.find("#add-email-field").click
      # fill_in "service_contact_emails_1", with: "person2@test.ok"
      select category.name, from: "Categories"
      select user.to_s, from: "Owners"
      fill_in "Version", with: "2.2.2"

      fill_in "service_sources_attributes_0_eid", with: "12345a"

      expect { click_on "Create Service" }.
        to change { user.owned_services.count }.by(1)


      expect(user.owned_services.last.order_target).to eq("email@domain.com")

      expect(page).to have_content("service name")
      expect(page).to have_content("service description")
      expect(page).to have_content("service tagline")
      expect(page).to have_content("Open Access")
      expect(page).to have_content("person1@test.ok")
      # expect(page).to have_content("person2@test.ok")
      expect(page).to have_content("Welcome!!!")
      expect(page).to have_content(scientific_domain.name)
      expect(page).to have_content(target_group.name)
      expect(page).to have_content(category.name)
      expect(page).to have_content("Publish")
      expect(page).to have_content("eic: 12345a")
      expect(page).to have_content("Alpha (min. TRL 5)")
      expect(page).to have_content("2.2.2")
    end

    scenario "I can see warning about no offers" do
      service = create(:service)

      visit backoffice_service_path(service)

      expect(page)
          .to have_content("The service has no offers." \
                           " Add one offer to make possible for a user to Access the service.")
    end

    scenario "I can preview service before create" do
      provider = create(:provider)
      scientific_domain = create(:scientific_domain)

      visit backoffice_services_path
      click_on "Create new Service"

      fill_in "Name", with: "service name"
      fill_in "Tagline", with: "tagline"
      fill_in "Description", with: "description"
      select scientific_domain.name, from: "Scientific domains"
      select provider.name, from: "Providers"

      click_on "Preview"

      expect(page).to have_content("service name")

      expect { click_on "Confirm changes" }.
        to change { Service.count }.by(1)
      expect(page).to have_content("service name")
    end

    scenario "I cannot create service with wrong logo file" do
      provider = create(:provider)
      scientific_domain = create(:scientific_domain)

      visit backoffice_services_path
      click_on "Create new Service"

      attach_file("service_logo", "spec/lib/images/invalid-logo.svg")
      fill_in "Name", with: "service name"
      fill_in "Description", with: "service description"
      fill_in "Tagline", with: "service tagline"
      select scientific_domain.name, from: "Scientific domains"
      select provider.name, from: "Providers"

      expect { click_on "Create Service" }.
        to change { user.owned_services.count }.by(0)

      expect(page).to have_content("Sorry, but the logo format you were trying to attach is not supported in the Marketplace.")
    end

    scenario "I can publish service" do
      service = create(:service, status: :draft)

      visit backoffice_service_path(service)
      click_on "Publish"

      expect(page).to have_content("Status: published")
    end

    scenario "I can publish as unverified service" do
      service = create(:service, status: :draft)

      visit backoffice_service_path(service)
      click_on "Publish as unverified service"

      expect(page).to have_content("Status: unverified")
    end

    scenario "I can unpublish service" do
      service = create(:service, status: :published)

      visit backoffice_service_path(service)
      click_on "Stop showing in the MP"

      expect(page).to have_content("Status: draft")
    end

    scenario "I can edit any service" do
      service = create(:service, name: "my service")

      visit backoffice_service_path(service)
      click_on "Edit"

      fill_in "Name", with: "updated name"
      click_on "Update Service"

      expect(page).to have_content("updated name")
    end

    scenario "I can see service preview" do
      service = create(:service, name: "my service")

      visit backoffice_service_path(service)
      click_on "Edit"

      fill_in "Name", with: "updated name"
      click_on "Preview"

      expect(page).to have_content("updated name")

      click_on "Confirm changes"
      expect(page).to have_content("updated name")
    end

    scenario "I can add new offer", js: true do
      service = create(:service, name: "my service", owners: [user])

      visit backoffice_service_path(service)
      click_on "Add new Offer", match: :first

      expect {
        fill_in "Name", with: "new offer 1"
        fill_in "Description", with: "test offer"
        find("li", text: "Input").click
        find("#attributes-list-button").first("svg").click

        within("div.card-text") do
          fill_in "Name", with: "new input parameter"
          fill_in "Hint", with: "test"
          fill_in "Unit", with: "days"
          select "integer", from: "Value type"
        end
        click_on "Create Offer"
      }.to change { service.offers.count }.by(1)

      expect(page).to have_content("test offer")
      service.reload
      expect(service.offers.last.name).to eq("new offer 1")
    end

    scenario "I can see warning about no published offers", js: true do
      service = create(:service)
      offer = create(:offer, status: "draft", service: service)

      visit backoffice_service_path(service)

      expect(page).to have_content("The service is published but has no published offers. " \
                                   "Publish one offer to make possible for a user to Access the service.")
      service.reload
      expect(service.offers).to eq([offer])
    end

    scenario "Offer are converted from markdown to html on service view" do
      offer = create(:offer,
                     name: "offer1",
                     description: "# Test offer\r\n\rDescription offer")

      visit backoffice_service_path(offer.service)

      find(".card-body h1", text: "Test offer")
      find(".card-body p", text: "Description offer")
    end

    scenario "I cannot add invalid offer", js: true do
      service = create(:service, name: "my service", owners: [user])

      visit backoffice_service_path(service)
      click_on "Add new Offer", match: :first

      expect {
        fill_in "Description", with: "test offer"
        click_on "Create Offer"
      }.to change { service.offers.count }.by(0)
    end

    scenario "I can edit offer", js: true do
      service = create(:service, name: "my service", status: :draft)
      parameter = build(:input_parameter,
                         name: "Number of CPU Cores",
                         hint: "Select number of cores you want",
                         value_type: "integer")
      offer = create(:offer, name: "offer1", description: "desc", service: service,
                     parameters: [parameter])

      visit backoffice_service_path(service)
      click_on(class: "edit-offer")

      fill_in "Description", with: "new desc"
      click_on "Update Offer"

      expect(page).to have_content("new desc")
      expect(offer.reload.description).to eq("new desc")
    end

    scenario "I can delete existed parameters", js: true do
      # Need to fix remove parameters
      service = create(:service, name: "my service", status: :draft)
      parameter = build(:input_parameter,
                         name: "Number of CPU Cores",
                         hint: "Select number of cores you want",
                         value_type: "integer")
      offer = create(:offer, name: "offer1", description: "desc", service: service,
                     parameters: [parameter, parameter])

      visit backoffice_service_path(service)
      click_on(class: "edit-offer")

      first("a[data-action='offer#remove']").first("i").click
      first("a[data-action='offer#remove']").first("i").click
      click_on "Update Offer"

      expect(offer.reload.parameters).to eq([])
    end


    scenario "I can delete offer" do
      service = create(:service, name: "my service", status: :draft)
      _offer = create(:offer, name: "offer1", description: "desc", service: service)

      visit backoffice_service_path(service)
      click_on(class: "delete-offer")

      expect(page).to have_content("This service has no offers")
    end

    scenario "I can see info if service has no offer" do
      service = create(:service, name: "my service")

      visit backoffice_service_path(service)

      expect(page).to have_content("This service has no offers")
    end

    scenario "I can change offer status from published to draft" do
      offer = create(:offer)

      visit backoffice_service_path(offer.service)
      click_on "Stop showing offer"

      expect(offer.reload.status).to eq("draft")
    end

    scenario "I can change offer status from draft to publish" do
      offer = create(:offer, status: :draft)

      visit backoffice_service_path(offer.service)
      click_on "Publish offer"

      expect(offer.reload.status).to eq("published")
    end

    scenario "I can change service status from publish to draft" do
      service = create(:service, name: "my service")

      visit backoffice_service_path(service)
      click_on("Stop showing in the MP")

      expect(page).to have_selector(:link_or_button, "Publish")
    end

    scenario "I can change external id of the service" do
      service = create(:service, name: "my service")
      _external_source = create(:service_source, eid: "777", source_type: "eic", service: service)

      visit backoffice_service_path(service)
      click_on "Edit"

      expect(page).to have_content("777")
      fill_in "service_sources_attributes_0_eid", with: "12345a"
      click_on "Update Service"
      expect(page).to have_content("eic: 12345a")
    end

    scenario "I can change upstream" do
      service = create(:service, name: "my service")
      external_source = create(:service_source, service: service)

      visit backoffice_service_path(service)
      click_on "Edit"

      select external_source.to_s, from: "Service Upstream"
      click_on "Update Service"
      expect(page).to have_content(external_source.to_s, count: 2)
    end

    scenario "if upstream is set to MP (nil) all fields should be enabled" do
      service = create(:service, name: "my service", upstream: nil)
      create(:service_source, service: service, source_type: :eic)

      visit backoffice_service_path(service)
      click_on "Edit"

      expect(page).to have_field "Logo", disabled: false
      expect(page).to have_field "Name", disabled: false
      expect(page).to have_field "Tag list", disabled: false
      expect(page).to have_field "Description", disabled: false
      expect(page).to have_field "Order type", disabled: false
      expect(page).to have_field "Categories", disabled: false
      expect(page).to have_field "Providers", disabled: false
      expect(page).to have_field "Platforms", disabled: false
      expect(page).to have_field "Scientific domains", disabled: false
      expect(page).to have_field "Dedicated For", disabled: false
      expect(page).to have_field "Owners", disabled: false
      expect(page).to have_field "service_contact_emails_0", disabled: false
      expect(page).to have_field "Service Order Target", disabled: false
      expect(page).to have_field "Places", disabled: false
      expect(page).to have_field "Languages", disabled: false
      expect(page).to have_field "Terms of use url", disabled: false
      expect(page).to have_field "Access policies url", disabled: false
      expect(page).to have_field "Sla url", disabled: false
      expect(page).to have_field "Webpage url", disabled: false
      expect(page).to have_field "Manual url", disabled: false
      expect(page).to have_field "Helpdesk url", disabled: false
      expect(page).to have_field "Helpdesk email", disabled: false
      expect(page).to have_field "Training information url", disabled: false
      expect(page).to have_field "Phase", disabled: false
      expect(page).to have_field "Restrictions", disabled: false
      expect(page).to have_field "Activate message", disabled: false
    end

    scenario "If EIC is selected as upstream fields imported from there should be disabled" do
      service = create(:service, name: "my service")
      external_source = create(:service_source, service: service, source_type: :eic)
      service.upstream = external_source
      service.save!

      visit backoffice_service_path(service)
      click_on "Edit"

      expect(page).to have_field "Logo", disabled: true
      expect(page).to have_field "Name", disabled: true
      expect(page).to have_field "Tag list", disabled: false
      expect(page).to have_field "Description", disabled: true
      expect(page).to have_field "Order type", disabled: true
      expect(page).to have_field "Categories", disabled: false
      expect(page).to have_field "Providers", disabled: true
      expect(page).to have_field "Platforms", disabled: false
      expect(page).to have_field "Scientific domains", disabled: false
      expect(page).to have_field "Dedicated For", disabled: false
      expect(page).to have_field "Owners", disabled: false
      expect(page).to have_field "service_contact_emails_0", disabled: false
      expect(page).to have_field "Service Order Target", disabled: false
      expect(page).to have_field "Places", disabled: true
      expect(page).to have_field "Languages", disabled: true
      expect(page).to have_field "Terms of use url", disabled: true
      expect(page).to have_field "Access policies url", disabled: true
      expect(page).to have_field "Sla url", disabled: true
      expect(page).to have_field "Webpage url", disabled: true
      expect(page).to have_field "Manual url", disabled: true
      expect(page).to have_field "Helpdesk url", disabled: true
      expect(page).to have_field "Helpdesk email", disabled: false
      expect(page).to have_field "Training information url", disabled: true
      expect(page).to have_field "Phase", disabled: true
      expect(page).to have_field "Restrictions", disabled: false
      expect(page).to have_field "Activate message", disabled: false
    end
  end

  context "as a service owner" do
    let(:user) { create(:user) }

    before { checkin_sign_in_as(user) }

    scenario "I can edit service draft" do
      service = create(:service, owners: [user], status: :draft)

      visit backoffice_service_path(service)
      click_on "Edit"

      fill_in "Name", with: "Owner can edit service draft"
      click_on "Update Service"
      expect(page).to have_content("Owner can edit service draft")
    end

    scenario "I can create new offer" do
      service = create(:service, owners: [user])

      visit backoffice_service_path(service)
      click_on "Add new Offer", match: :first

      fill_in "Name", with: "New offer"
      fill_in "Description", with: "New fancy offer"
      click_on "Create Offer"

      expect(page).to have_content("New offer")
      expect(page).to have_content("New fancy offer")
    end
  end
end
