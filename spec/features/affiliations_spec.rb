# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Affiliations" do
  include OmniauthHelper

  let(:user) { create(:user) }

  context "as logged in user" do
    before { checkin_sign_in_as(user) }

    scenario "I can see all my (and only my) affiliations on profile" do
      create(:affiliation, organization: "org1", user: user)
      create(:affiliation, organization: "org2", user: user)
      create(:affiliation, organization: "org3")

      visit profile_path

      expect(page).to have_content("org1")
      expect(page).to have_content("org2")
      expect(page).to_not have_content("org3")
    end

    scenario "I can create new affiliation" do
      visit profile_path
      click_on "Add new affiliation"

      fill_in "Organization", with: "my org"
      fill_in "Department", with: "depart"
      fill_in "Email", with: "johndoe@uni.edu"
      fill_in "Phone", with: "12345678"
      fill_in "Webpage", with: "http://my.uni.edu"
      fill_in "Supervisor", with: "My Supervisor"
      fill_in "Supervisor profile", with: "http://supervisor.edu"

      expect { click_on "Create Affiliation" }.
        to change { user.affiliations.count }.by(1)

      expect(page).to have_content("New affiliation - last step")
      expect(page).to have_content("johndoe@uni.edu")
    end

    scenario "I can confirm new affiliation" do
      create(:affiliation, user: user, token: "secret")

      visit affiliation_confirmations_path(at: "secret")

      expect(page).to have_content("Affiliation successfully activated")
    end

    scenario "I cannot confirm not owned affiliation" do
      create(:affiliation, token: "secret")

      visit affiliation_confirmations_path(at: "secret")

      expect(page).to have_content("not belong to you")

    end

    scenario "I can edit my affiliation" do
      affiliation = create(:affiliation, organization: "my org", user: user)

      visit edit_profile_affiliation_path(affiliation)
      fill_in "Organization", with: "new org"
      click_on "Update Affiliation"
      affiliation.reload

      expect(affiliation.organization).to eq("new org")
    end

    scenario "I cannot remove an affiliation with a project item" do
      affiliation = create(:affiliation, user: user)

      visit profile_path

      affiliation.status = :active
      affiliation.save
      create(:project_item, affiliation: affiliation)

      click_on "Delete"

      expect(page).to have_content("You cannot remove an affiliation which has a project item")
    end
  end
end
