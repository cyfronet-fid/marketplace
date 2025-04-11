# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Service ordering", end_user_frontend: true do
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

      expect(page).to have_text("Access the service")
    end

    scenario "I see order open access service button" do
      open_access_service = create(:open_access_service)
      create(:open_access_offer, service: open_access_service)

      visit service_path(open_access_service)

      expect(page).to have_text("Access the service")
    end

    scenario "I can order service" do
      offer, _second_offer = create_list(:offer, 2, service: service)

      visit service_path(service)

      click_on "Access the service", match: :first

      # Step 1
      expect(page).to have_current_path(service_choose_offer_path(service))
      expect(page).to have_text("Select an offer or service bundle")
      expect(page).to have_selector(:link_or_button, "Next", exact: true)

      choose "customizable_project_item_offer_id_#{offer.iid}"
      click_on "Next", match: :first

      # Step 2
      expect(page).to have_current_path(service_information_path(service))
      expect(page).to have_selector(:link_or_button, "Next", exact: true)

      click_on "Next", match: :first

      # Step 4
      expect(page).to have_current_path(service_summary_path(service))
      expect(page).to have_selector(:link_or_button, "Send access request", exact: true)

      select "Services"

      expect { click_on "Send access request", match: :first }.to change { ProjectItem.count }.by(1)
      project_item = ProjectItem.last
      expect(project_item.offer_id).to eq(offer.id)
      expect(project_item.properties).to eq([])

      # Project item page
      expect(page).to have_current_path(project_service_path(project_item.project, project_item))
      expect(page).to have_content(service.name)
    end

    scenario "I can order service with offer containing range" do
      parameter = build(:range_parameter, name: "Attribute 1", max: 100)
      offer = create(:offer, service: service, parameters: [parameter])

      visit service_path(service)

      click_on "Access the service", match: :first

      # Step 2
      expect(page).to have_current_path(service_information_path(service))
      expect(page).to have_selector(:link_or_button, "Next", exact: true)

      click_on "Next", match: :first

      # Step 3
      expect(page).to have_current_path(service_configuration_path(service))
      expect(page).to have_selector(:link_or_button, "Next", exact: true)

      fill_in "parameter_#{offer.parameters[0].id}", with: "95"

      click_on "Next", match: :first

      # Step 4
      expect(page).to have_current_path(service_summary_path(service))
      expect(page).to have_selector(:link_or_button, "Send access request", exact: true)
      select "Services"

      expect { click_on "Send access request", match: :first }.to change { ProjectItem.count }.by(1)
      project_item = ProjectItem.last
      expect(project_item.offer_id).to eq(offer.id)

      # Project item page
      expect(page).to have_current_path(project_service_path(project_item.project, project_item))
      expect(page).to have_content(service.name)
    end

    %i[open_access_service fully_open_access_service other_service order_required_service].each do |type|
      scenario "I cannot order #{type} service twice in one project" do
        service = create(type)
        _offer =
          create(
            :offer,
            service: service,
            internal: false,
            order_type: service.order_type,
            order_url: service.order_url
          )
        _default_project = user.projects.find_by(name: "Services")

        visit service_path(service)

        click_on "Access the service"

        # Information step
        click_on "Next", match: :first

        # Project selection
        select "Services", from: "customizable_project_item_project_id"

        expect { click_on "Pin!", match: :first }.to change { ProjectItem.count }.by(1)

        visit service_path(service)

        click_on "Access the service"

        # Information step
        click_on "Next", match: :first

        # Project selection
        select "Services", from: "customizable_project_item_project_id"

        expect do
          click_on "Pin!", match: :first
          expect(page).to have_text("already pinned with this offer")
        end.to change { ProjectItem.count }.by(0)
      end
    end

    [:order_required_service].each do |type|
      scenario "I can order #{type} service twice in one project" do
        service = create(type)
        _offer =
          create(:offer, service: service, internal: true, order_type: service.order_type, order_url: service.order_url)
        _default_project = user.projects.find_by(name: "Services")

        visit service_path(service)

        click_on "Access the service"
        click_on "Next", match: :first

        select "Services", from: "customizable_project_item_project_id"

        expect { click_on "Send access request", match: :first }.to change { ProjectItem.count }.by(1)

        visit service_path(service)

        click_on "Access the service"
        click_on "Next", match: :first

        select "Services", from: "customizable_project_item_project_id"

        expect { click_on "Send access request", match: :first }.to change { ProjectItem.count }.by(1)
      end
    end

    scenario "I can order bundle service twice in one project" do
      service = create(:service)
      service2 = create(:service)
      bundled =
        create(
          :offer,
          service: service2,
          internal: true,
          order_type: service2.order_type,
          order_url: service2.order_url
        )
      bundle_offer =
        create(
          :offer,
          service: service,
          internal: true,
          bundle_exclusive: true,
          order_type: service.order_type,
          order_url: service.order_url
        )
      _bundle =
        create(:bundle, service: service, order_type: service.order_type, main_offer: bundle_offer, offers: [bundled])

      _default_project = user.projects.find_by(name: "Services")

      visit service_path(service)

      click_on "Access the service"

      click_on "Next", match: :first

      select "Services", from: "customizable_project_item_project_id"

      expect { click_on "Send access request", match: :first }.to change { ProjectItem.count }.by(2)

      visit service_path(service)

      click_on "Access the service"

      click_on "Next", match: :first

      select "Services", from: "customizable_project_item_project_id"

      expect { click_on "Send access request", match: :first }.to change { ProjectItem.count }.by(2)
    end

    scenario "I can order bundle service and its bundled service" do
      service = create(:service)
      service2 = create(:service)
      bundled = create(:offer, service: service2, order_type: service2.order_type, order_url: service2.order_url)
      bundle_offer = create(:offer, service: service, order_type: service.order_type, order_url: service.order_url)
      bundle =
        create(:bundle, service: service, order_type: service.order_type, main_offer: bundle_offer, offers: [bundled])

      _default_project = user.projects.find_by(name: "Services")

      visit service_path(service)

      click_on "Access the service"

      choose "customizable_project_item_bundle_id_#{bundle.iid}"

      click_on "Next", match: :first
      click_on "Next", match: :first

      select "Services", from: "customizable_project_item_project_id"

      expect { click_on "Send access request", match: :first }.to change { ProjectItem.count }.by(2)

      visit service_path(service2)

      click_on "Access the service"
      click_on "Next", match: :first

      select "Services", from: "customizable_project_item_project_id"

      expect { click_on "Send access request", match: :first }.to change { ProjectItem.count }.by(1)
    end

    scenario "I cannot order every 'open_access' type offer twice" do
      service = create(:open_access_service)
      open_access =
        create(
          :offer,
          service: service,
          internal: false,
          iid: 1,
          order_type: :open_access,
          order_url: service.order_url
        )
      fully_open_access =
        create(
          :offer,
          service: service,
          internal: false,
          iid: 2,
          order_type: :fully_open_access,
          order_url: service.order_url
        )
      other =
        create(:offer, service: service, internal: false, iid: 3, order_type: :other, order_url: service.order_url)
      order_required_external =
        create(
          :offer,
          service: service,
          internal: false,
          iid: 4,
          order_type: :order_required,
          order_url: service.order_url
        )
      _default_project = user.projects.find_by(name: "Services")
      service.offers_count = 4

      visit service_path(service)

      click_on "Access the service"

      expect(page).to have_text "Offer selection"

      # Information step - open_access
      choose "customizable_project_item_offer_id_#{open_access.iid}"
      click_on "Next", match: :first
      click_on "Next", match: :first

      select "Services", from: "customizable_project_item_project_id"

      expect { click_on "Pin!", match: :first }.to change { ProjectItem.count }.by(1)

      visit service_path(service)

      click_on "Access the service"

      choose "customizable_project_item_offer_id_#{open_access.iid}"
      click_on "Next", match: :first
      click_on "Next", match: :first

      select "Services", from: "customizable_project_item_project_id"

      expect do
        click_on "Pin!", match: :first
        expect(page).to have_text("already pinned with this offer")
      end.to change { ProjectItem.count }.by(0)

      visit service_path(service)

      click_on "Access the service"

      # Information step - fully_open_access
      choose "customizable_project_item_offer_id_#{fully_open_access.iid}"
      click_on "Next", match: :first
      click_on "Next", match: :first

      select "Services", from: "customizable_project_item_project_id"

      expect { click_on "Pin!", match: :first }.to change { ProjectItem.count }.by(1)

      visit service_path(service)

      click_on "Access the service"

      choose "customizable_project_item_offer_id_#{fully_open_access.iid}"
      click_on "Next", match: :first
      click_on "Next", match: :first

      select "Services", from: "customizable_project_item_project_id"

      expect do
        click_on "Pin!", match: :first
        expect(page).to have_text("already pinned with this offer")
      end.to change { ProjectItem.count }.by(0)

      visit service_path(service)

      click_on "Access the service"

      # Information step - other
      choose "customizable_project_item_offer_id_#{other.iid}"
      click_on "Next", match: :first
      click_on "Next", match: :first

      select "Services", from: "customizable_project_item_project_id"

      expect { click_on "Pin!", match: :first }.to change { ProjectItem.count }.by(1)

      visit service_path(service)

      click_on "Access the service"

      choose "customizable_project_item_offer_id_#{other.iid}"
      click_on "Next", match: :first
      click_on "Next", match: :first

      select "Services", from: "customizable_project_item_project_id"

      expect do
        click_on "Pin!", match: :first
        expect(page).to have_text("already pinned with this offer")
      end.to change { ProjectItem.count }.by(0)

      visit service_path(service)
      click_on "Access the service"

      # Information step - order_required_external
      choose "customizable_project_item_offer_id_#{order_required_external.iid}"
      click_on "Next", match: :first
      click_on "Next", match: :first

      select "Services", from: "customizable_project_item_project_id"

      expect { click_on "Pin!", match: :first }.to change { ProjectItem.count }.by(1)

      visit service_path(service)

      click_on "Access the service"

      choose "customizable_project_item_offer_id_#{order_required_external.iid}"
      click_on "Next", match: :first
      click_on "Next", match: :first

      select "Services", from: "customizable_project_item_project_id"

      expect do
        click_on "Pin!", match: :first
        expect(page).to have_text("already pinned with this offer")
      end.to change { ProjectItem.count }.by(0)
    end

    scenario "Skip offers selection when only one offer" do
      create(:offer, service: service)

      visit service_path(service)

      click_on "Access the service"

      expect(page).to have_current_path(service_information_path(service))
    end

    scenario "I'm redirected from information step into service offers when offer is not chosen" do
      create_list(:offer, 2, service: service)

      visit service_information_path(service)

      expect(page).to have_current_path(service_choose_offer_path(service))
    end

    scenario "I'm redirected into service offers when offer is not chosen" do
      create_list(:offer, 2, service: service)

      visit service_configuration_path(service)

      expect(page).to have_current_path(service_choose_offer_path(service))
    end

    scenario "I'm redirected into order summary when project is not chosen" do
      create(:offer, service: service)

      visit service_path(service)

      click_on "Access the service"

      # Go directly to summary page
      visit service_summary_path(service)
      click_on "Send access request", match: :first

      expect(page).to have_current_path(service_summary_path(service))
      expect(page).to have_text("can't be blank")
    end

    scenario "I can order open access service" do
      open_access_service = create(:open_access_service)
      offer = create(:open_access_offer, service: open_access_service)
      default_project = user.projects.find_by(name: "Services")

      visit service_path(open_access_service)

      click_on "Access the service"

      # Information page
      click_on "Next", match: :first

      # Summary page
      expect(page).to have_current_path(service_summary_path(open_access_service))
      expect(page).to have_selector(:link_or_button, "Pin!", exact: true)
      select "Services"

      expect { click_on "Pin!", match: :first }.to change { ProjectItem.count }.by(1)
      project_item = ProjectItem.last

      expect(project_item.offer).to eq(offer)
      expect(project_item.project).to eq(default_project)
    end

    scenario "I can order catalog service" do
      external_service = create(:external_service)
      offer = create(:external_offer, service: external_service)
      default_project = user.projects.find_by(name: "Services")

      visit service_path(external_service)

      click_on "Access the service"
      click_on "Next", match: :first

      # Summary page
      expect(page).to have_current_path(service_summary_path(external_service))
      expect(page).to have_selector(:link_or_button, "Pin!", exact: true)
      select "Services"

      expect { click_on "Pin!", match: :first }.to change { ProjectItem.count }.by(1)
      project_item = ProjectItem.last

      expect(project_item.offer).to eq(offer)
      expect(project_item.project).to eq(default_project)
    end

    scenario "I cannot order service without offers", js: true do
      service = create(:service)

      visit service_path(service)

      expect(page).to_not have_text("Access the service")
    end

    scenario "I can create new project on order summary view", js: true do
      Capybara.page.current_window.resize_to("1600", "1024")
      service = create(:service)
      create(:offer, service: service)

      visit service_path(service)

      click_on "Access the service"
      click_on "Next", match: :first

      click_on "Add new project"
      within("#form-modal") do
        fill_in "Project name", with: "New project"
        select "Single user", from: "Customer typology"
        fill_in "Email", with: "john@doe.com"
        fill_in "Organization", with: "Home corp."
        fill_in "Webpage", with: "http://home.corp.com"
        fill_in "Reason to request access to the EOSC resources", with: "Some reason"
        select "Non-European", from: "Origin country"
      end
      click_on "Create new project"

      expect(page).to have_select("customizable_project_item_project_id", selected: "New project")

      new_project = Project.all.last
      expect(new_project.name).to eq("New project")
      expect(user.projects.find { |project| project.name == "New project" }).to_not be_nil
    end

    scenario "I will stay in project edit modal while trying to create empty project", js: true do
      Capybara.page.current_window.resize_to("1600", "1024")
      service = create(:service)
      create(:offer, service: service)

      visit service_path(service)

      click_on "Access the service"
      click_on "Next", match: :first
      click_on "Add new project"

      click_on "Create new project"
      within("#form-modal") do
        expect(page).to have_button("Create new project")
        expect(page).to have_selector("input[placeholder='+ start typing to add']")
      end

      # fail form validation by not filling any fields
      click_on "Create new project"

      within("#form-modal") do
        expect(page).to have_button("Create new project")
        expect(page).to have_selector("input[placeholder='+ start typing to add']")
      end
    end

    scenario "I can create new project for private company typology", js: true do
      Capybara.page.current_window.resize_to("1600", "1024")
      service = create(:service)
      scientific_domain = create(:scientific_domain)
      create(:offer, service: service)

      visit service_path(service)

      click_on "Access the service"
      click_on "Next", match: :first
      click_on "Add new project"
      within("#form-modal") do
        fill_in "Project name", with: "New project"
        fill_in "Reason to request access to the EOSC resources", with: "To pass test"
        within ".project_scientific_domains" do
          find("label", text: "Scientific domains").click
          sleep(0.5)
          find("div", class: "choices__item", text: scientific_domain.name).click
        end

        select "Representing a private company", from: "Customer typology"
        fill_in "Email", with: "john@doe.com"
        select "Non-European", from: "Origin country"

        expect(page).to have_field("Company name")
        expect(page).to have_field("Company website url")

        fill_in "Company name", with: "New company name"
        fill_in "Company website url", with: "https://www.company.name"

        click_on "Create new project"
      end
      expect(page).to have_select("customizable_project_item_project_id", selected: "New project")
      expect(page).to have_text(scientific_domain.name)
      expect(page).to have_text("New company name")
      expect(page).to have_text("https://www.company.name")
      expect(page).to have_text("Non-European")

      new_project = Project.all.last
      expect(new_project.name).to eq("New project")
      expect(user.projects.find { |project| project.name == "New project" }).to_not be_nil
    end

    scenario "Voucher inputs should not be visible in voucher disabled offer" do
      service = create(:service)
      _offer = create(:offer, service: service, voucherable: false)

      visit service_path(service)

      click_on "Access the service"

      # Information step
      click_on "Next", match: :first

      # Step 3
      expect(page).to have_current_path(service_summary_path(service))
      expect(page).to_not have_text("Voucher")
    end

    scenario "Voucher ID input should be visible for voucher enabled service", js: true do
      Capybara.page.current_window.resize_to("1600", "1024")
      service = create(:service)
      _offer = create(:offer, service: service, voucherable: true)

      visit service_path(service)

      click_on "Access the service"
      click_on "Next", match: :first

      # Step 2
      expect(page).to have_text("Voucher ID")
      fill_in "Voucher ID", with: "11111-22222-33333-44444"

      click_on "Next", match: :first

      # Step 3
      expect(page).to have_text("Voucher")
      expect(page).to have_text("11111-22222-33333-44444")
    end

    scenario "Voucher ID input should not be visible if 'request voucher' radio is set", js: true do
      Capybara.page.current_window.resize_to("1600", "1024")
      _offer = create(:offer, service: service, voucherable: true)

      visit service_path(service)

      click_on "Access the service"
      click_on "Next", match: :first

      # Step 2
      find("label", id: "ask").click
      expect(page).to_not have_text("Voucher ID")

      click_on "Next", match: :first

      # Step 3
      sleep(1)
      expect(current_path).to eq service_summary_path(service)
      click_on "Back to previous step - Configuration"

      # Step 2 - again
      sleep(1)
      expect(current_path).to eq service_configuration_path(service)
      expect(page).to_not have_text("Voucher ID")
      find("label", id: "have").click
      fill_in "Voucher ID", with: "11111-22222-33333-44444"
      click_on "Next", match: :first

      # Step 3
      sleep(1)
      expect(current_path).to eq service_summary_path(service)
      expect(page).to have_text("11111-22222-33333-44444")
      click_on "Back to previous step - Configuration"

      # Step 2 - again
      sleep(1)
      expect(current_path).to eq service_configuration_path(service)
      expect(page).to have_selector("input[value='11111-22222-33333-44444']")
      find("label", id: "ask").click
      click_on "Next", match: :first

      # Step 3
      sleep(1)
      expect(current_path).to eq service_summary_path(service)
      expect(page).to_not have_text("11111-22222-33333-44444")
    end

    context "On information step" do
      scenario "I can see link to external service webpage when offert is open_access" do
        service = create(:open_access_service)
        create(:open_access_offer, service: service)

        visit service_path(service)

        click_on "Access the service"

        expect(page).to have_link("Go to the service")
      end

      scenario "I cannot see link to external service webpage when offert is orderable" do
        service = create(:service)
        create(:offer, service: service)

        visit service_path(service)

        click_on "Access the service"

        expect(page).to_not have_link("Go to the service")
        expect(page).to_not have_link("Order externally")
        expect(page).to_not have_link("Link")
      end

      scenario "I can see link to external service webpage when offert is external" do
        service = create(:service)
        create(:external_offer, service: service)

        visit service_path(service)

        click_on "Access the service"

        expect(page).to have_link("Go to the order website")
      end
    end

    context "#bundles" do
      scenario "I can order a service bundle" do
        child1 = create(:offer_with_parameters)
        child2 = create(:offer_with_parameters)
        child3 = create(:offer_with_parameters)
        parent = create(:offer, service: service)
        bundle = create(:bundle, service: service, main_offer: parent, offers: [child1, child2])

        visit service_offers_path(service)

        click_on "Select bundle"

        # Step 1 is skipped
        # Step 2
        expect(page).to have_current_path(service_information_path(service))
        click_on "Next", match: :first

        # Step 3
        expect(page).to have_current_path(service_configuration_path(service))
        expect(page).to have_text("Bundle configuration")

        expect(page).to have_css("#parameter_#{child1.parameters[0].id}")
        expect(page).to have_css("#parameter_#{child2.parameters[0].id}")

        fill_in "parameter_#{child1.parameters[0].id}", with: "value1"
        fill_in "parameter_#{child2.parameters[0].id}", with: "value2"

        click_on "Next", match: :first

        # Step 4
        expect(page).to have_current_path(service_summary_path(service))
        expect(page).to have_text("value1")
        expect(page).to have_text("value2")

        select "Services"

        expect { click_on "Send access request", match: :first }.to change { ProjectItem.count }.by(3)

        pi1, pi2, pi3 = ProjectItem.all
        expect(pi1.offer_id).to eq(parent.id)
        expect(pi1.properties).to eq([])
        expect(pi2.offer_id).to eq(child1.id)
        expect(pi2.properties.length).to eq(1)
        expect(pi2.properties[0]["value"]).to eq("value1")
        expect(pi3.offer_id).to eq(child2.id)
        expect(pi3.properties.length).to eq(1)
        expect(pi3.properties[0]["value"]).to eq("value2")

        # Project item page
        expect(page).to have_current_path(project_service_path(pi1.project, pi1))
        expect(page).to have_content("BUNDLE")
        expect(page).to have_content(service.name)
        expect(page).to have_content(child1.service.name)
        expect(page).to have_content(child2.service.name)

        # The bundle reference should stay after unbundling offers

        bundle.update(offers: [child3])

        visit project_services_path(pi1.project)

        expect(page).to have_content("Bundle")
        expect(page).to have_content(service.name)
        expect(page).to have_content(child1.service.name)
        expect(page).to have_content(child2.service.name)
      end
    end
  end

  context "as anonymous user" do
    scenario "I can see service offers" do
      service = create(:service)
      o1, o2 = create_list(:offer, 2, service: service)

      visit service_path(service)

      expect(page).to have_selector(:link_or_button, "Access the service", exact: true)

      click_on "Access the service", match: :first

      expect(page).to have_text("Select an offer or service bundle")
      expect(page).to have_text(o1.name)
      expect(page).to have_text(o2.name)
    end

    scenario "I need to log in to configure my order" do
      service = create(:service)
      create(:offer, service: service)
      user = build(:user)
      stub_checkin(user)

      visit service_choose_offer_path(service)

      expect do
        # If new user is logged in using checkin new user record is created
        click_on "Next", match: :first
      end.to change { User.count }.by(1)

      expect(page).to have_current_path(service_summary_path(service))
      expect(User.last.full_name).to eq(user.full_name)
    end

    scenario "I can see Access the service button" do
      service = create(:service)
      create(:offer, service: service)

      visit service_path(service)

      expect(page).to have_selector(:link_or_button, "Access the service", exact: true)
    end

    scenario "I can see openaccess service order button" do
      open_access_service = create(:open_access_service)
      create(:open_access_offer, service: open_access_service)

      visit service_path(open_access_service)

      expect(page).to have_selector(:link_or_button, "Access the service", exact: true)
    end

    scenario "I can see catalog service button" do
      external = create(:external_service)
      create(:external_offer, service: external)

      visit service_path(external)
      expect(page).to have_selector(:link_or_button, "Access the service", exact: true)
    end
  end
end
