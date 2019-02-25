# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Service ordering" do
  include OmniauthHelper


  context "as logged in user" do

    let(:user) { create(:user) }
    let(:service) { create(:service) }

    before { checkin_sign_in_as(user) }

    scenario "I see project_item service button" do
      create(:offer, service: service)

      visit service_path(service)

      expect(page).to have_text("Order")
    end

    scenario "I see order open acces service button" do
      open_access_service = create(:open_access_service)
      create(:offer, service: open_access_service)

      visit service_path(open_access_service)

      expect(page).to have_text("Add to a project")
    end

    scenario "I can order service" do
      offer, _seconds_offer = create_list(:offer, 2, service: service)
      affiliation = create(:affiliation, status: :active, user: user)
      research_area = create(:research_area)

      visit service_path(service)

      click_on "Order", match: :first

      # Step 1
      expect(page).to have_current_path(service_offers_path(service))
      expect(page).to have_text(service.title)
      expect(page).to have_selector(:link_or_button,
                                    "Next", exact: true)

      choose "project_item_offer_id_#{offer.iid}"
      click_on "Next", match: :first

      # Step 2
      expect(page).to have_current_path(service_configuration_path(service))
      expect(page).to have_selector(:link_or_button,
                                    "Next", exact: true)

      select "Services"
      select affiliation.organization
      select research_area.name, from: "Research area"
      select "Single user", from: "Customer typology"
      fill_in "Access reason", with: "To pass test"
      fill_in "Additional information", with: "Additional information test"

      click_on "Next", match: :first

      # Step 3
      expect(page).to have_current_path(service_summary_path(service))
      expect(page).to have_selector(:link_or_button,
                                    "Order", exact: true)
      expect(page).to have_text("Single user")
      expect(page).to have_text("To pass test")
      expect(page).to have_text("Additional information test")

      expect do
        check "Accept terms and conditions"
        click_on "Order", match: :first
      end.to change { ProjectItem.count }.by(1)
      project_item = ProjectItem.last
      expect(project_item.offer_id).to eq(offer.id)

      # Summary
      expect(page).to have_current_path(service_summary_path(service))
      expect(page).to have_selector(:link_or_button,
                                    "Go to requested service", exact: true)

      click_on "Go to requested service"

      # Project item page
      expect(page).to have_current_path(project_item_path(project_item))
      expect(page).to have_content(service.title)
    end

    scenario "I can order service without terms and contitions" do
      service = create(:service, terms_of_use_url: "")
      offer, _seconds_offer = create_list(:offer, 2, service: service)
      affiliation = create(:affiliation, status: :active, user: user)
      research_area = create(:research_area)

      visit service_path(service)

      click_on "Order", match: :first

      # Step 1

      choose "project_item_offer_id_#{offer.iid}"
      click_on "Next", match: :first

      # Step 2

      select "Services"
      select affiliation.organization
      select research_area.name, from: "Research area"
      select "Single user", from: "Customer typology"
      fill_in "Access reason", with: "To pass test"
      fill_in "Additional information", with: "Additional information test"

      click_on "Next", match: :first

      # Step 3
      expect(page).not_to have_text("Accept terms and conditions")

      expect do
        click_on "Order", match: :first
      end.to change { ProjectItem.count }.by(1)
    end

    scenario "I cannot order open_access service twice in one project" do
      open_access_service = create(:open_access_service)
      _offer = create(:offer, service: open_access_service)
      _default_project = user.projects.find_by(name: "Services")

      visit service_path(open_access_service)

      click_on "Add to a project"

      # Project selection
      select "Services", from: "project_item_project_id"
      click_on "Next", match: :first

      expect do
        check "Accept terms and conditions"
        click_on "Add to a project", match: :first
      end.to change { ProjectItem.count }.by(1)

      visit service_path(open_access_service)

      click_on "Add to a project"

      select "Services", from: "project_item_project_id"
      click_on "Next", match: :first

      expect(page).to have_current_path(service_configuration_path(open_access_service))
      expect(page).to have_text("You cannot add open access service #{open_access_service.title} to project Services twice")
    end

    scenario "Skip offers selection when only one offer" do
      create(:offer, service: service)

      visit service_path(service)

      click_on "Order"

      expect(page).to have_current_path(service_configuration_path(service))
    end

    scenario "I'm redirected into service offers when offer is not chosen" do
      create_list(:offer, 2, service: service)

      visit service_configuration_path(service)

      expect(page).to have_current_path(service_offers_path(service))
    end

    scenario "I'm redirected into service configuration when order is not valid" do
      create(:offer, service: service)

      visit service_path(service)

      click_on "Order"

      # Go directly to summary page
      visit service_summary_path(service)

      expect(page).to have_current_path(service_configuration_path(service))
    end

    scenario "I can order open acces service" do
      open_access_service = create(:open_access_service)
      offer = create(:offer, service: open_access_service)
      default_project = user.projects.find_by(name: "Services")

      visit service_path(open_access_service)

      click_on "Add to a project"

      # Project selection
      expect(page).to have_current_path(service_configuration_path(open_access_service))
      select "Services"
      click_on "Next", match: :first


      # Summary page
      expect(page).to have_current_path(service_summary_path(open_access_service))
      expect(page).to have_selector(:link_or_button,
                                    "Add to a project", exact: true)

      expect do
        check "Accept terms and conditions"
        click_on "Add to a project", match: :first
      end.to change { ProjectItem.count }.by(1)
      project_item = ProjectItem.last

      expect(project_item.offer).to eq(offer)
      expect(project_item.project).to eq(default_project)
    end

    scenario "I cannot order service without offers", js: true do
      service = create(:service)

      visit service_path(service)

      expect(page).to_not have_text("Order")
    end

    scenario "I can create new project on order configuration view", js: true do
      service = create(:service)
      create(:offer, service: service)

      visit service_path(service)

      click_on "Order"
      click_on "Add new project"
      within("#ajax-modal") do
        fill_in "Name", with: "New project"
      end
      click_on "Create new project"

      expect(page).to have_select("project_item_project_id", selected: "New project")

      new_project = Project.all.last
      expect(new_project.name).to eq("New project")
      expect(user.projects.find { |project| project.name == "New project" }).to_not be_nil
    end

    scenario "I can create new project for private company typology", js: true do
      service = create(:service)
      create(:offer, service: service)

      visit service_path(service)

      click_on "Order"
      click_on "Add new project"
      within("#ajax-modal") do
        fill_in "Name", with: "New project"
        select "Representing a private company", from: "Customer typology"

        expect(page).to have_field("Company name")
        expect(page).to have_field("Company website url")

        fill_in "Company name", with: "Company name"
        fill_in "Company website url", with: "https://www.company.name"
        click_on "Create new project"
      end

      expect(page).to have_select("project_item_project_id", selected: "New project")
      expect(page).to have_field("Company name", with: "Company name")
      expect(page).to have_field("Company website url", with: "https://www.company.name")

      new_project = Project.all.last
      expect(new_project.name).to eq("New project")
      expect(user.projects.find { |project| project.name == "New project" }).to_not be_nil
    end

    scenario "Voucher inputs should not be visible in voucher disabled offer" do
      service = create(:service)
      offer = create(:offer, service: service, voucherable: false)
      affiliation = create(:affiliation, status: :active, user: user)
      research_area = create(:research_area)

      visit service_path(service)

      click_on "Order"

      # Step 2
      expect(page).to_not have_text("Voucher")

      select "Services"
      select affiliation.organization
      select research_area.name, from: "Research area"
      select "Single user", from: "Customer typology"
      fill_in "Access reason", with: "To pass test"

      click_on "Next", match: :first

      # Step 3
      expect(page).to_not have_text("Voucher")
    end

    scenario "Voucher ID input should be visible for voucher enabled service" do
      service = create(:service)
      offer = create(:offer, service: service, voucherable: true)
      affiliation = create(:affiliation, status: :active, user: user)
      research_area = create(:research_area)

      visit service_path(service)

      click_on "Order"

      # Step 2
      expect(page).to have_text("Voucher ID")
      fill_in "Voucher ID", with: "11111-22222-33333-44444"

      select "Services"
      select affiliation.organization
      select research_area.name, from: "Research area"
      select "Single user", from: "Customer typology"
      fill_in "Access reason", with: "To pass test"

      click_on "Next", match: :first

      # Step 3
      expect(page).to have_text("Voucher")
      expect(page).to have_text("11111-22222-33333-44444")
    end

    scenario "Voucher ID input should not be visible if 'request voucher' radio is set", js: true do
      offer = create(:offer, service: service, voucherable: true)
      affiliation = create(:affiliation, status: :active, user: user)
      research_area = create(:research_area)

      visit service_path(service)

      click_on "Order"
      # Step 2
      find("label", id: "ask").click
      expect(page).to_not have_text("Voucher ID")


      select "Services"
      select affiliation.organization
      select research_area.name, from: "Research area"
      select "Single user", from: "Customer typology"
      fill_in "Access reason", with: "To pass test"
      click_on "Next", match: :first

      # Step 3
      expect(current_path).to eq service_summary_path(service)
      click_on "Back to previous step - configuration"

      # Step 2 - again
      expect(current_path).to eq service_configuration_path(service)
      expect(page).to_not have_text("Voucher ID")
      find("label", id: "have").click
      fill_in "Voucher ID", with: "11111-22222-33333-44444"
      click_on "Next", match: :first

      # Step 3
      expect(current_path).to eq service_summary_path(service)
      expect(page).to have_text("11111-22222-33333-44444")
      click_on "Back to previous step - configuration"

      # Step 2 - again
      expect(current_path).to eq service_configuration_path(service)
      expect(page).to have_selector("input[value='11111-22222-33333-44444']")
      find("label", id: "ask").click
      click_on "Next", match: :first

      # Step 3
      expect(current_path).to eq service_summary_path(service)
      expect(page).to_not have_text("11111-22222-33333-44444")
    end
  end

  context "as anonymous user" do
    scenario "I nead to login to order service" do
      service = create(:service)
      create_list(:offer, 2, service: service)
      user = create(:user)

      visit service_path(service)

      expect(page).to have_selector(:link_or_button, "Order", exact: true)

      click_on "Order", match: :first

      checkin_sign_in_as(user)

      expect(page).to have_current_path(service_offers_path(service))
      expect(page).to have_text(service.title)
    end

    scenario "I can see order button" do
      service = create(:service)
      create(:offer, service: service)

      visit service_path(service)

      expect(page).to have_selector(:link_or_button, "Order", exact: true)
    end

    scenario "I can see openaccess service order button" do
      open_access_service =  create(:open_access_service)
      create(:offer, service: open_access_service)

      visit service_path(open_access_service)

      expect(page).to have_selector(:link_or_button, "Add to a project", exact: true)
      expect(page).to have_selector(:link_or_button, "Access the service", exact: true)
    end

    scenario "I can see catalog service button" do
      catalog = create(:service, service_type: :catalog)

      visit service_path(catalog)

      expect(page).to have_selector(:link_or_button, "Access the service", exact: true)
    end
  end
end
