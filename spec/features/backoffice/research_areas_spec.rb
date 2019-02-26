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
      click_on "Add research area"

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
  end
end
