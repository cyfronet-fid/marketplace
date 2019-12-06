# frozen_string_literal: true

require "rails_helper"

RSpec.feature "My Services" do
  include OmniauthHelper

  context "as logged in user" do
    let(:user) { create(:user) }
    let(:service) { create(:service) }
    let(:offer) { create(:offer, service: service) }

    before { checkin_sign_in_as(user) }


    scenario "I can see only my projects" do
      p1, p2 = create_list(:project, 2, user: user)
      not_owned = create(:project)

      visit projects_path

      expect(page).to have_text(p1.name)
      expect(page).to have_text(p2.name)
      expect(page).to_not have_text(not_owned.name)
    end

    scenario "I can see my projects services" do
      project = create(:project, user: user)
      create(:project_item, project: project, offer: offer)

      visit project_services_path(project)

      expect(page).to have_text(service.title)
    end

    scenario "I can see project_item details" do
      project = create(:project, user: user)
      project_item = create(:project_item, project: project, offer: offer)

      visit project_service_path(project, project_item)

      expect(page).to have_text(project_item.service.title)
    end

    # Test added after hotfix for a bug in `project_items/show.html.haml:30` (v1.2.0)
    scenario "I can see project_item details without research_area" do
      offer = create(:offer, service: create(:open_access_service))
      project = create(:project, user: user, research_areas: [])
      project_item = create(:project_item, project: project, offer: offer)

      visit project_service_path(project, project_item)

      expect(page).to have_text(project_item.service.title)
    end

    scenario "I cannot see other users project_items" do
      other_user_project_item = create(:project_item, offer: offer)

      visit project_service_path(other_user_project_item.project,
                                 other_user_project_item)

      # TODO: the given service is showing up in Others pane in home view
      # expect(page).to_not have_text(other_user_project_item.service.title)
      expect(page).to have_text("not authorized")
    end

    scenario "I can see project_item change history", js: true do
      project = create(:project, user: user)
      project_item = create(:project_item, project: project, offer: offer)

      project_item.new_status(status: :created, message: "Service request created")
      project_item.new_status(status: :registered, message: "Service request registered")
      project_item.new_status(status: :ready, message: "Service is ready")

      visit project_service_timeline_path(project, project_item)

      expect(page).to have_text("ready")

      expect(page).to have_text("Service request created")
      expect(page).to have_text("Service request registered")
      expect(page).to have_text("Service request ready")
      expect(page).to have_text("Service is ready")
    end

    scenario "I can see voucher id" do
      project = create(:project, user: user)
      project_item = create(:project_item, project: project, offer: create(:offer, voucherable: true),
                            voucher_id: "V123V")

      visit project_service_path(project, project_item)

      expect(page).to have_text(project_item.voucher_id)
    end

    scenario "I cannot see voucher entry" do
      project = create(:project, user: user)
      project_item = create(:project_item, project: project, offer: offer)

      visit project_service_path(project, project_item)

      expect(page).to_not have_text("Voucher")
    end

    scenario "I can see that voucher has been requested" do
      project = create(:project, user: user)
      project_item = create(:project_item, project: project, offer: create(:offer, voucherable: true),
                            request_voucher: true)

      visit project_service_path(project, project_item)

      expect(page).to have_text("Vouchers\nRequested")
    end

    scenario "I cannot see review section" do
      project = create(:project, user: user)
      project_item = create(:project_item, project: project, offer: offer)

      visit project_service_path(project, project_item)

      expect(page).to_not have_text("Your review")
    end

    scenario "I can see review section" do
      project = create(:project, user: user)
      project_item = create(:project_item, project: project, offer: offer, status: :ready)
      travel 1.day
      visit project_service_path(project, project_item)

      expect(page).to have_text("Your review")
      expect(page).to have_text("please share your experience so far")
    end

    scenario "I can ask question about my project_item" do
      project = create(:project, user: user)
      project_item = create(:project_item, project: project, offer: offer)

      visit project_service_conversation_path(project, project_item)
      fill_in "message_message", with: "This is my question"
      click_button "Send message"

      expect(page).to have_text("This is my question")
    end

    scenario "question message is mandatory" do
      project = create(:project, user: user)
      project_item = create(:project_item, project: project, offer: offer)

      visit project_service_conversation_path(project, project_item)
      click_button "Send message"

      expect(page).to have_text("Message can't be blank")
    end
  end

  context "as anonymous user" do
    scenario "I don't see my services page" do
      visit root_path

      expect(page).to_not have_text("My projects")
    end
  end
end
