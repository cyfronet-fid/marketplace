# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Service ordering" do
  include OmniauthHelper


  context "as logged in user" do
    let(:user) do
      create(:user).tap { |u| create(:project, name: "Services", user: u, reason_for_access: "To pass test") }
    end
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

      click_on "Next", match: :first

      # Step 3
      expect(page).to have_current_path(service_summary_path(service))
      expect(page).to have_selector(:link_or_button,
                                    "Order", exact: true)

      expect(page).to have_text("Single user")
      expect(page).to have_text("To pass test")

      expect do
        click_on "Order", match: :first
      end.to change { ProjectItem.count }.by(1)
      project_item = ProjectItem.last
      expect(project_item.offer_id).to eq(offer.id)
      expect(project_item.properties).to eq([])

      # Project item page
      expect(page).to have_current_path(project_item_path(project_item))
      expect(page).to have_content(service.title)
    end

    scenario "I can order service with offert containing range" do
      offer = create(:offer, service: service,
                          parameters: [{ "id": "id1",
                                         "label": "Attribute 1",
                                         "type": "range",
                                         "value_type": "integer",
                                         "value": 1,
                                         "config": {
                                           "minimum": 1,
                                           "maximum": 100,
                                         } }])


      visit service_path(service)

      click_on "Order", match: :first

      # Step 2
      expect(page).to have_current_path(service_configuration_path(service))
      expect(page).to have_selector(:link_or_button,
                                    "Next", exact: true)

      fill_in "Attribute 1", with: "95"
      select "Services"


      click_on "Next", match: :first

      # Step 3
      expect(page).to have_current_path(service_summary_path(service))
      expect(page).to have_selector(:link_or_button,
                                    "Order", exact: true)
      expect(page).to have_text("Single user")
      expect(page).to have_text("To pass test")

      expect do
        click_on "Order", match: :first
      end.to change { ProjectItem.count }.by(1)
      project_item = ProjectItem.last
      expect(project_item.offer_id).to eq(offer.id)

      # Project item page
      expect(page).to have_current_path(project_item_path(project_item))
      expect(page).to have_content(service.title)
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
        fill_in "Project name", with: "New project"
        select "Single user", from: "Customer typology"
        fill_in "Email", with: "john@doe.com"
        fill_in "Organization", with: "Home corp."
        fill_in "Webpage", with: "http://home.corp.com"
        fill_in "Reason to request access to the EOSC services", with: "Some reason"
        select "non-European", from: "Customer country"
      end
      click_on "Create new project"

      expect(page).to have_select("project_item_project_id", selected: "New project")

      new_project = Project.all.last
      expect(new_project.name).to eq("New project")
      expect(user.projects.find { |project| project.name == "New project" }).to_not be_nil
    end

    scenario "I will stay in project edit modal while trying to create empty project", js: true do
      service = create(:service)
      create(:offer, service: service)

      visit service_path(service)

      click_on "Order"
      click_on "Add new project"

      click_on "Create new project"
      within("#ajax-modal") do
        expect(page).to have_button("Create new project")
      end

      click_on "Create new project"
      within("#ajax-modal") do
        expect(page).to have_button("Create new project")
      end
    end

    scenario "I can create new project for private company typology", js: true do
      service = create(:service)
      research_area = create(:research_area)
      create(:offer, service: service)

      visit service_path(service)

      click_on "Order"
      click_on "Add new project"
      within("#ajax-modal") do
        fill_in "Project name", with: "New project"
        fill_in "Reason to request access to the EOSC services", with: "To pass test"
        within ".project_research_areas" do
          find("label", text: "Research areas").click
          find("div", class: "choices__item", text: research_area.name).click
        end


        select "Representing a private company", from: "Customer typology"
        fill_in "Email", with: "john@doe.com"
        select "non-European", from: "Customer country"

        expect(page).to have_field("Company name")
        expect(page).to have_field("Company website url")

        fill_in "Company name", with: "New company name"
        fill_in "Company website url", with: "https://www.company.name"

        click_on "Create new project"
      end
      expect(page).to have_select("project_item_project_id", selected: "New project")
      expect(page).to have_text(research_area.name)
      expect(page).to have_text("New company name")
      expect(page).to have_text("https://www.company.name")
      expect(page).to have_text("non-European")

      new_project = Project.all.last
      expect(new_project.name).to eq("New project")
      expect(user.projects.find { |project| project.name == "New project" }).to_not be_nil
    end

    scenario "Voucher inputs should not be visible in voucher disabled offer" do
      service = create(:service)
      _offer = create(:offer, service: service, voucherable: false)

      visit service_path(service)

      click_on "Order"

      # Step 2
      expect(page).to_not have_text("Voucher")

      select "Services"

      click_on "Next", match: :first

      # Step 3
      expect(page).to_not have_text("Voucher")
    end

    scenario "Voucher ID input should be visible for voucher enabled service" do
      service = create(:service)
      _offer = create(:offer, service: service, voucherable: true)

      visit service_path(service)

      click_on "Order"

      # Step 2
      expect(page).to have_text("Voucher ID")
      fill_in "Voucher ID", with: "11111-22222-33333-44444"

      select "Services"


      click_on "Next", match: :first

      # Step 3
      expect(page).to have_text("Voucher")
      expect(page).to have_text("11111-22222-33333-44444")
    end

    scenario "Voucher ID input should not be visible if 'request voucher' radio is set", js: true do
      _offer = create(:offer, service: service, voucherable: true)

      visit service_path(service)

      click_on "Order"
      # Step 2
      find("label", id: "ask").click
      expect(page).to_not have_text("Voucher ID")


      select "Services"
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
      stub_checkin(user)

      visit service_path(service)

      expect(page).to have_selector(:link_or_button, "Order", exact: true)

      click_on "Order", match: :first

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
