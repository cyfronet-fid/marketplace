# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Research areas in backoffice" do
  include OmniauthHelper

  context "As a service portolio manager" do
    let(:user) { create(:user, roles: [:service_portfolio_manager]) }

    before { checkin_sign_in_as(user) }

    scenario "I can see all research areas" do
      create(:research_area, name: "ra1")
      create(:research_area, name: "ra2")

      visit backoffice_research_areas_path

      expect(page).to have_content("ra1")
      expect(page).to have_content("ra2")
    end

    scenario "I can see research area details" do
      parent = create(:research_area, name: "parent")
      child = create(:research_area, name: "child", parent: parent)

      visit backoffice_research_area_path(child)

      expect(page).to have_content("child")
      expect(page).to have_content("parent")
    end

    scenario "I can create new research area" do
      create(:research_area, name: "parent")

      visit backoffice_research_areas_path
      click_on "Add new Research Area"

      fill_in "Name", with: "My new research area"
      select "parent", from: "Parent"

      expect { click_on "Create Research area" }.
        to change { ResearchArea.count }.by(1)

      expect(page).to have_content("My new research area")
      expect(page).to have_content("parent")
    end

    scenario "I can edit research area" do
      create(:research_area, name: "parent")
      research_area = create(:research_area, name: "Old name")

      visit edit_backoffice_research_area_path(research_area)

      fill_in "Name", with: "New name"
      select "parent", from: "Parent"
      click_on "Update Research area"

      expect(page).to have_content("New name")
      expect(page).to have_content("parent")
    end

    context "with research area as parent containing services" do
      let!(:parent) { create(:research_area, name: "parent") }
      let!(:leaf) { create(:research_area, name: "leaf") }
      let!(:services) { create_list(:service, 3, research_areas: [parent]) }

      before(:each) do
        visit backoffice_research_areas_path
        click_on "Add new Research Area"

        fill_in "Name", with: "My new research area"
        select "parent", from: "Parent"

        click_on "Create Research area"
      end

      context "I can't create research area with parent contains services" do
        it "shows error" do
          expect(page).to have_text("Parent has services")
          expect(page.status_code).to eq(400)
        end

        it "shows possible options to move services" do
          expect(page).to have_text(services.first.title)
          expect(page).to have_text(services.second.title)
          expect(page).to have_text(services.third.title)

          expect(page).to have_button("Create Research area and move services to the selected")
        end
      end
      context "move actions" do
        scenario "I can move services to different research area" do
          select "leaf", from: "Possible choices"
          expect { click_on "Create Research area and move services to the selected one" }.
              to change { ResearchArea.count }.by(1)

          expect([leaf.services]).to contain_exactly(services)

          expect(page).to have_content("My new research area")
          expect(page).to have_content("parent")
        end

        scenario "I can move services to current" do
          select "My new research area", from: "Possible choices"
          expect { click_on "Create Research area and move services to the selected one" }.
              to change { ResearchArea.count }.by(1)

          expect(page).to have_text(services.first.title)
          expect(page).to have_text(services.second.title)
          expect(page).to have_text(services.third.title)
        end
      end
    end
  end
end
