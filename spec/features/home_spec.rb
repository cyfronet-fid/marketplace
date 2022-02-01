# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Home", end_user_frontend: true do
  include OmniauthHelper

  scenario "searching should go to /services with correct query", js: true do
    visit "/"

    fill_in "q", with: "Something"
    click_on(id: "query-submit")

    expect(page).to have_current_path(services_path, ignore_query: true)
    expect(page).to have_selector("#q[value='Something']")
  end

  context "service opinions", skip: "due to diff between egi mp and default mp" do
    let(:service_opinion_published) { create(:service_opinion) }
    let(:service_opinion_draft) { create(:service_opinion) }

    %i[draft deleted].each do |status|
      it "should show service opinions only for published resources" do
        draft = service_opinion_draft.project_item.service
        draft.update(status: status)
        service = service_opinion_published.project_item.service

        visit root_path

        expect(page).to_not have_text("There are no reviews available.")

        expect(page).to_not have_css("#opinion-link", text: draft.name)
        expect(page).to have_css("#opinion-link", text: service.name)
      end
    end
  end

  context "services carousel" do
    let!(:service1) { create(:service, description: "published-service-1", status: :published) }
    let!(:service2) { create(:service, description: "published-service-2", status: :published) }
    let!(:service_draft) { create(:service, status: :draft) }

    xit "should show only published service in Popular services section" do
      visit "/"
      expect(page).to have_text "Popular services"
      expect(page).to have_text(service1.name)
      expect(page).to have_text(service2.name)
      expect(page).not_to have_text(service_draft.name)
    end
  end

  context "lead_sections" do
    context "admin user" do
      let(:admin) { create(:user, roles: [:admin]) }
      before { checkin_sign_in_as(admin) }

      it "should see error", skip: "due to diff between egi mp and default mp" do
        visit "/"
        expect(page).to have_text("Cannot find lead_section with slug \"learn-more\"")
        expect(page).to have_text("Cannot find lead_section with slug \"use-cases\"")
      end

      it "should see section", skip: "due to diff between egi mp and default mp" do
        lead_section = create(:lead_section, slug: "learn-more", title: "Learn More Section")
        create(:lead, lead_section: lead_section)
        visit "/"
        expect(page).to_not have_text("Cannot find lead_section with slug \"learn-more\"")
        expect(page).to have_text("Cannot find lead_section with slug \"use-cases\"")
        expect(page).to have_text("Learn More Section")
      end

      it "should see welcome modal only once", js: true do
        visit admin_features_path

        click_on "Enable welcome modal"
        expect(page).to have_current_path(admin_features_path)
        expect(page).to have_content("Welcome modal enabled for all first logged-in users")
        admin.update(show_welcome_popup: true)

        visit root_path

        expect(page).to have_content("New functionality arrived!")

        click_on "I'll do it later"

        visit root_path

        expect(page).to_not have_content("New functionality arrived!")
      end
    end

    context "user" do
      let(:user) { create(:user) }
      before { checkin_sign_in_as(user) }

      it "shouldn't see warning" do
        visit "/"
        expect(page).to_not have_text("Cannot find lead_section with slug \"learn-more\"")
        expect(page).to_not have_text("Cannot find lead_section with slug \"use-cases\"")
      end

      it "should see section" do
        lead_section = create(:lead_section, slug: "learn-more", title: "Learn More Section")
        create(:lead, lead_section: lead_section)
        visit "/"
        expect(page).to_not have_text("Cannot find lead_section with slug \"learn-more\"")
        expect(page).to_not have_text("Cannot find lead_section with slug \"use-cases\"")
        expect(page).to have_text("Learn More Section")
      end
    end
  end
end
