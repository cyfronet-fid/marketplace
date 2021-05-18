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

    scenario "I can create new service with default offer" do
      category = create(:category)
      provider = create(:provider)
      scientific_domain = create(:scientific_domain)
      resource_organisation = create(:provider)
      platform = create(:platform)
      funding_body = create(:funding_body)
      funding_program = create(:funding_program)
      trl = create(:trl)
      life_cycle_status = create(:life_cycle_status)
      target_user = create(:target_user)
      access_type = create(:access_type)
      access_mode = create(:access_mode)


      visit backoffice_services_path
      click_on "Create new Resource"

      fill_in "Name", with: "service name"
      fill_in "Description", with: "service description"
      fill_in "Terms of use", with: "service terms of use"
      fill_in "Tagline", with: "service tagline"
      fill_in "service_multimedia_0", with: "https://sample.url"
      select "English", from: "Language availability"
      select "Poland", from: "Geographical availabilities"
      select "Poland", from: "Resource geographic locations"
      select trl.name, from: "Trl"
      select life_cycle_status.name, from: "Life cycle status"
      select funding_body.name, from: "Funding bodies"
      select funding_program.name, from: "Funding programs"
      select target_user.name, from: "Dedicated For"
      fill_in "service_main_contact_attributes_first_name", with: "John"
      fill_in "service_main_contact_attributes_last_name", with: "Doe"
      fill_in "service_main_contact_attributes_email", with: "john@doe.com"
      fill_in "service_public_contacts_attributes_0_first_name", with: "Jane"
      fill_in "service_public_contacts_attributes_0_last_name", with: "Doe"
      fill_in "service_public_contacts_attributes_0_email", with: "jane@doe.com"
      select access_mode.name, from: "Access modes"
      select access_type.name, from: "Access types"
      fill_in "Terms of use url", with: "https://sample.url"
      fill_in "Access policies url", with: "https://sample.url"
      fill_in "Privacy policy url", with: "https://sample.url"
      fill_in "Sla url", with: "https://sample.url"
      fill_in "service_use_cases_url_0", with: "https://sample.url"
      fill_in "Webpage url", with: "https://sample.url"
      fill_in "Manual url", with: "https://sample.url"
      fill_in "Helpdesk url", with: "https://sample.url"
      fill_in "Training information url", with: "https://sample.url"
      fill_in "Restrictions", with: "Reaserch affiliation needed"
      fill_in "Activate message", with: "Welcome!!!"
      fill_in "service_certifications_0", with: "ISO-639"
      fill_in "service_standards_0", with: "standard"
      fill_in "service_open_source_technologies_0", with: "opensource"
      fill_in "service_grant_project_names_0", with: "grantname"
      fill_in "service_changelog_0", with: "fixed bug"
      select scientific_domain.name, from: "Scientific domains"
      select provider.name, from: "Providers"
      select "open_access", from: "Order type"
      select resource_organisation.name, from: "Resource organisation"
      select platform.name, from: "Platforms"
      select category.name, from: "Categories"
      select user.to_s, from: "Owners"
      fill_in "Version", with: "2.2.2"

      fill_in "service_sources_attributes_0_eid", with: "12345a"

      expect { click_on "Create Resource" }.
        to change { user.owned_services.count }.by(1)
               .and change { Offer.count }.by(1)

      expect(page).to have_content("service name")
      expect(page).to have_content("service description")
      expect(page).to have_content("service tagline")
      expect(page).to have_content("Open Access")
      expect(page).to have_content(scientific_domain.name)
      expect(page).to have_content(target_user.name)
      expect(page).to have_content("Publish")

      click_on "Details"

      expect(page).to have_content(funding_body.name)
      expect(page).to have_content(funding_program.name)
      expect(page).to have_content("jane@doe.com")
      expect(page).to have_content(access_type.name)
      expect(page).to have_content(access_mode.name)
      expect(page).to have_content("ISO-639")
      expect(page).to have_content("standard")
      expect(page).to have_content("opensource")
      expect(page).to have_content("grantname")
      expect(page).to have_content("2.2.2")
      expect(page).to have_content(trl.name.upcase)
      expect(page).to have_content(life_cycle_status.name)
    end

    scenario "I can add additional public contacts", js: true do
      service = create(:service)

      visit edit_backoffice_service_path(service)

      find_button("Contact").click

      fill_in "service_public_contacts_attributes_0_first_name", with: "Jane"
      fill_in "service_public_contacts_attributes_0_last_name", with: "Doe"
      fill_in "service_public_contacts_attributes_0_email", with: "jane@doe.com"

      click_on "Add additional public contact"

      fill_in "service_public_contacts_attributes_1_first_name", with: "Johny"
      fill_in "service_public_contacts_attributes_1_last_name", with: "Does"
      fill_in "service_public_contacts_attributes_1_email", with: "johny@does.com"

      click_on "Add additional public contact"

      fill_in "service_public_contacts_attributes_2_first_name", with: "John"
      fill_in "service_public_contacts_attributes_2_last_name", with: "Doe"
      fill_in "service_public_contacts_attributes_2_email", with: "john@doe.com"

      click_on "Update Resource"

      click_on "Details"


      expect(page).to have_content("jane@doe.com")
      expect(page).to have_content("johny@does.com")
      expect(page).to have_content("john@doe.com")
    end

    scenario "I can remove additional public contacts", js: true do
      service = create(:service)
      public_contacts = create_list(:public_contact, 2, contactable: service)

      visit edit_backoffice_service_path(service)

      find_button("Contact").click

      find("a", id: "public-contact-delete-0").click
      find("a", id: "public-contact-delete-1").click

      click_on "Update Resource"

      expect(page).to_not have_content(public_contacts.first.email)
      expect(page).to_not have_content(public_contacts.second.email)
    end

    scenario "I can see warning about no offers" do
      service = create(:service)

      visit backoffice_service_path(service)

      expect(page)
          .to have_content("This resource has no offers. " \
                           "Add one offer to make possible for a user to Access the service.")
    end

    scenario "I can preview service before create" do
      provider = create(:provider)
      scientific_domain = create(:scientific_domain)
      resource_organisation = create(:provider)

      visit backoffice_services_path
      click_on "Create new Resource"

      fill_in "Name", with: "service name"
      fill_in "Tagline", with: "tagline"
      fill_in "Description", with: "description"
      select scientific_domain.name, from: "Scientific domains"
      select provider.name, from: "Providers"
      select "Poland", from: "Geographical availabilities"
      select resource_organisation.name, from: "Resource organisation"

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
      click_on "Create new Resource"

      attach_file("service_logo", "spec/lib/images/invalid-logo.svg")
      fill_in "Name", with: "service name"
      fill_in "Description", with: "service description"
      fill_in "Tagline", with: "service tagline"
      select scientific_domain.name, from: "Scientific domains"
      select provider.name, from: "Providers"

      expect { click_on "Create Resource" }.
        to change { user.owned_services.count }.by(0)

      expect(page).to have_content("The logo format you're trying to attach is not supported.")
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
      click_on "Publish as unverified resource"

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
      click_on "Update Resource"

      expect(page).to have_content("updated name")
    end

    scenario "I can update service with default offer with parameters" do
      service = create(:service, name: "my service", offers: [create(:offer_with_parameters)])

      parameters = service.offers.first.parameters
      parameter = parameters.first

      expect(service.offers.count).to eq(1)
      service.offers.each do |offer|
        expect(offer.order_url).to_not eq("http://order.com")
        expect(offer.order_type).to_not eq("fully_open_access")
      end

      visit backoffice_service_path(service)
      click_on "Edit resource"

      fill_in "Name", with: "updated name"
      fill_in "Order url", with: "http://order.com"
      select "fully_open_access", from: "Order type"

      click_on "Update Resource"

      expect(page).to have_content("updated name")

      service.reload

      offer = service.offers.first

      expect(page).to have_text(offer.parameters.first.name)

      expect(offer.order_url).to eq("http://order.com")
      expect(offer.order_type).to eq("fully_open_access")

      expect(offer.parameters.size).to eq(1)

      expect(offer.parameters.first.id).to eq(parameter.id)
      expect(offer.parameters.first.name).to eq(parameter.name)
      expect(offer.parameters.first.value_type).to eq(parameter.value_type)
      expect(offer.parameters.first.hint).to eq(parameter.hint)
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
      click_on "Add new offer"

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

      service.reload
      expect(service.offers.last.name).to eq("new offer 1")
    end

    scenario "I can update default offer through service", js: true do
      service = create(:service, name: "my service", owners: [user])
      create(:offer, service: service)

      service.reload

      expect(service.offers.count).to eq(1)
      service.offers.each do |offer|
        expect(offer.order_type).to eq("order_required")
        expect(offer.order_url).to_not eq("http://google.com")
      end

      visit backoffice_service_path(service)

      click_on "Edit resource"

      find_button("Order").click

      select "open_access", from: "Order type"
      fill_in "Order url", with: "http://google.com"

      click_on "Update Resource"

      service.reload
      service.offers.each do |offer|
        expect(offer.order_type).to eq("open_access")
        expect(offer.order_url).to eq("http://google.com")
      end
    end

    scenario "I can see warning about no published offers", js: true do
      service = create(:service)

      visit backoffice_service_path(service)

      expect(page).to have_content("This resource has no offers. " \
                                   "Add one offer to make possible for a user to Access the service.")
      offer = create(:offer, service: service)
      service.reload
      expect(service.offers).to eq([offer])
    end

    scenario "Offer are converted from markdown to html on service view" do
      offer = create(:offer,
                     name: "offer1",
                     description: "# Test offer\r\n\rDescription offer")
      create(:offer, service: offer.service)

      visit backoffice_service_path(offer.service)

      find(".card-body h1", text: "Test offer")
      find(".card-body p", text: "Description offer")
    end

    scenario "I cannot add invalid offer", js: true do
      service = create(:service, name: "my service", owners: [user], offers: [create(:offer)])

      visit backoffice_service_path(service)
      click_on "Add new offer"

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
      create(:offer, service: service)

      service.reload

      visit backoffice_service_path(service)
      first(".btn.btn-outline-secondary.font-weight-bold").click

      fill_in "Description", with: "new desc"
      click_on "Update Offer"

      expect(page).to have_content("new desc")
      expect(offer.reload.description).to eq("new desc")
    end

    scenario "I can delete existed parameters", js: true do
      service = create(:service, name: "my service", status: :draft)
      parameter = build(:input_parameter,
                         name: "Number of CPU Cores",
                         hint: "Select number of cores you want",
                         value_type: "integer")
      offer = create(:offer, name: "offer1", description: "desc", service: service,
                     parameters: [parameter, parameter])
      create(:offer, service: service)

      visit backoffice_service_path(service)
      first(".btn.btn-outline-secondary.font-weight-bold").click

      first("a[data-action='offer#remove']").first("i").click
      click_on "Update Offer"

      parameters = offer.reload.parameters

      expect(parameters.size).to eq(1)
      expect(parameters.first.name).to eq("Number of CPU Cores")
      expect(parameters.first.hint).to eq("Select number of cores you want")
      expect(parameters.first.value_type).to eq("integer")
    end

    scenario "I can delete existed parameters in default offer", js: true do
      service = create(:service, name: "my service", offers: [create(:offer_with_parameters)])

      visit backoffice_service_path(service)
      click_on "Edit parameters"

      find("a[data-action='offer#remove']").click

      click_on "Update Offer"

      expect(service.offers.first.reload.parameters).to eq([])
    end


    scenario "I can delete offer if they are more than 2" do
      service = create(:service, name: "my service")
      _offer = create(:offer, name: "offer1", description: "desc", service: service)
      _second_offer = create(:offer, service: service)

      service.reload

      visit edit_backoffice_service_offer_path(service, _offer)

      click_on "Delete Offer"

      expect(page).to have_content("Offer removed successfully")
    end

    scenario "I can see info if service has no offer" do
      service = create(:service, name: "my service")

      visit backoffice_service_path(service)

      expect(page).to have_content("This resource has no offers. " \
                                   "Add one offer to make possible for a user to Access the service.")
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
      click_on "Update Resource"
      service.reload
      expect(service.sources.first.eid).to eq("12345a")
    end

    scenario "I can change upstream" do
      service = create(:service, name: "my service")
      external_source = create(:service_source, service: service)

      visit backoffice_service_path(service)
      click_on "Edit"

      select external_source.to_s, from: "Resource Upstream"
      click_on "Update Resource"

      service.reload

      expect(service.upstream_id).to eq(external_source.id)
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
      expect(page).to have_field "Funding bodies", disabled: false
      expect(page).to have_field "Funding programs", disabled: false
      expect(page).to have_field "Language availability", disabled: false
      expect(page).to have_field "Geographical availabilities", disabled: false
      expect(page).to have_field "Terms of use url", disabled: false
      expect(page).to have_field "Access policies url", disabled: false
      expect(page).to have_field "Sla url", disabled: false
      expect(page).to have_field "Webpage url", disabled: false
      expect(page).to have_field "Manual url", disabled: false
      expect(page).to have_field "Helpdesk url", disabled: false
      expect(page).to have_field "Helpdesk email", disabled: false
      expect(page).to have_field "Training information url", disabled: false
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

      expect(page).to have_field "Name", disabled: true
      expect(page).to have_field "Resource organisation", disabled: true
      expect(page).to have_field "Logo", disabled: true
      expect(page).to have_field "Tag list", disabled: true
      expect(page).to have_field "Description", disabled: true
      expect(page).to have_field "Tagline", disabled: true
      expect(page).to have_field "service_multimedia_0", disabled: true
      expect(page).to have_field "service_use_cases_url_0", disabled: true
      expect(page).to have_field "Order type", disabled: true
      expect(page).to have_field "Order url", disabled: true
      expect(page).to have_field "Categories", disabled: false
      expect(page).to have_field "Access types", disabled: true
      expect(page).to have_field "Access modes", disabled: true
      expect(page).to have_field "Providers", disabled: true
      expect(page).to have_field "Platforms", disabled: false
      expect(page).to have_field "service_main_contact_attributes_first_name", disabled: true
      expect(page).to have_field "service_main_contact_attributes_last_name", disabled: true
      expect(page).to have_field "service_main_contact_attributes_email", disabled: true
      expect(page).to have_field "service_main_contact_attributes_phone", disabled: true
      expect(page).to have_field "service_main_contact_attributes_organisation", disabled: true
      expect(page).to have_field "service_main_contact_attributes_position", disabled: true
      expect(page).to have_field "service_public_contacts_attributes_0_first_name", disabled: true
      expect(page).to have_field "service_public_contacts_attributes_0_last_name", disabled: true
      expect(page).to have_field "service_public_contacts_attributes_0_email", disabled: true
      expect(page).to have_field "service_public_contacts_attributes_0_phone", disabled: true
      expect(page).to have_field "service_public_contacts_attributes_0_organisation", disabled: true
      expect(page).to have_field "service_public_contacts_attributes_0_position", disabled: true
      expect(page).to have_field "Helpdesk email", disabled: true
      expect(page).to have_field "Security contact email", disabled: true
      expect(page).to have_field "Trl", disabled: true
      expect(page).to have_field "Life cycle status", disabled: true
      expect(page).to have_field "service_certifications_0", disabled: true
      expect(page).to have_field "service_standards_0", disabled: true
      expect(page).to have_field "service_open_source_technologies_0", disabled: true
      expect(page).to have_field "Version", disabled: true
      expect(page).to have_field "Last update", disabled: true
      expect(page).to have_field "service_changelog_0", disabled: true
      expect(page).to have_field "service_related_platforms_0", disabled: true
      expect(page).to have_field "Required Resources", disabled: true
      expect(page).to have_field "Related Resources", disabled: true
      expect(page).to have_field "Scientific domains", disabled: true
      expect(page).to have_field "Dedicated For", disabled: true
      expect(page).to have_field "Funding bodies", disabled: true
      expect(page).to have_field "Funding programs", disabled: true
      expect(page).to have_field "service_grant_project_names_0", disabled: true
      expect(page).to have_field "Owners", disabled: false
      expect(page).to have_field "Language availability", disabled: true
      expect(page).to have_field "Geographical availabilities", disabled: true
      expect(page).to have_field "Resource geographic locations", disabled: true
      expect(page).to have_field "Terms of use url", disabled: true
      expect(page).to have_field "Access policies url", disabled: true
      expect(page).to have_field "Sla url", disabled: true
      expect(page).to have_field "Webpage url", disabled: true
      expect(page).to have_field "Manual url", disabled: true
      expect(page).to have_field "Helpdesk url", disabled: true
      expect(page).to have_field "Training information url", disabled: true
      expect(page).to have_field "Status monitoring url", disabled: true
      expect(page).to have_field "Status monitoring url", disabled: true
      expect(page).to have_field "Maintenance url", disabled: true
      expect(page).to have_field "Payment model url", disabled: true
      expect(page).to have_field "Pricing url", disabled: true
      expect(page).to have_field "Restrictions", disabled: false
      expect(page).to have_field "Activate message", disabled: false
      expect(page).to have_field "service_upstream_id", disabled: false
      expect(page).to have_field "service_sources_attributes_0_eid", disabled: false
      expect(page).to have_field "Synchronized at", disabled: true
    end

    scenario "I can edit offer OMS", js: true do
      oms1 = create(:oms, name: "OMS1", custom_params: { "foo": { "mandatory": true, "default": "baz" } })
      oms2 = create(:oms, name: "OMS2", custom_params: {})
      service = create(:service, name: "my service", status: :draft)
      offer = create(:offer, name: "offer1", description: "desc", service: service, internal: false)
      create(:offer, service: service)

      service.reload

      visit backoffice_service_path(service)
      first(".btn.btn-outline-secondary.font-weight-bold").click

      check "Use EOSC Portal as the order management platform"
      select "OMS1", from: "Order Management System"
      click_on "Update Offer"

      offer.reload
      expect(offer.internal).to be_falsey

      fill_in "Foo", with: "bar"
      click_on "Update Offer"

      offer.reload
      expect(offer.internal).to be_truthy
      expect(offer.primary_oms).to eq(oms1)
      expect(offer.oms_params).to eq({ "foo" => "bar" })

      first(".btn.btn-outline-secondary.font-weight-bold").click

      select "OMS2", from: "Order Management System"
      click_on "Update Offer"

      offer.reload
      expect(offer.primary_oms).to eq(oms2)
      expect(offer.oms_params).to eq({})
    end

    scenario "I can edit default offer OMS", js: true do
      oms1 = create(:oms, name: "OMS1", custom_params: { "foo": { "mandatory": true, "default": "baz" } })
      oms2 = create(:oms, name: "OMS2", custom_params: {})
      service = create(:service, name: "my service", status: :draft)
      offer = create(:offer, name: "offer1", description: "desc", service: service, internal: false)

      service.reload

      visit backoffice_service_path(service)
      first(".btn.btn-outline-secondary.font-weight-bold").click

      check "Use EOSC Portal as the order management platform"
      select "OMS1", from: "Order Management System"
      click_on "Update Offer"

      offer.reload
      expect(offer.internal).to be_falsey

      fill_in "Foo", with: "bar"
      click_on "Update Offer"

      offer.reload
      expect(offer.internal).to be_truthy
      expect(offer.primary_oms).to eq(oms1)
      expect(offer.oms_params).to eq({ "foo" => "bar" })

      first(".btn.btn-outline-secondary.font-weight-bold").click

      select "OMS2", from: "Order Management System"
      click_on "Update Offer"

      offer.reload
      expect(offer.primary_oms).to eq(oms2)
      expect(offer.oms_params).to eq({})
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
      click_on "Update Resource"
      expect(page).to have_content("Owner can edit service draft")
    end

    scenario "I can create new offer" do
      service = create(:service, owners: [user])
      create(:offer, service: service)

      visit backoffice_service_path(service)
      click_on "Add new offer", match: :first

      fill_in "Name", with: "New offer"
      fill_in "Description", with: "New fancy offer"
      click_on "Create Offer"

      expect(page).to have_content("New offer has been created")
    end
  end
end
