# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Affiliations" do
  include OmniauthHelper

  let(:user) { create(:user) }

  context "as logged in user" do
    before { checkin_sign_in_as(user) }

    scenario "I can see Affiliation link on my profile page" do
      visit profile_path

      expect(page).to have_content("Affiliations")
    end

    scenario "I can see all my (and only my) affiliations" do
      create(:affiliation, organization: "org1", user: user)
      create(:affiliation, organization: "org2", user: user)
      create(:affiliation, organization: "org3")

      visit profile_affiliations_path

      expect(page).to have_content("org1")
      expect(page).to have_content("org2")
      expect(page).to_not have_content("org3")
    end

    scenario "I can create new affiliation" do
      visit profile_affiliations_path
      click_on "New affiliation"

      fill_in "Organization", with: "my org"
      fill_in "Department", with: "depart"
      fill_in "Email", with: "johndoe@uni.edu"
      fill_in "Phone", with: "12345678"
      fill_in "Webpage", with: "http://my.uni.edu"
      fill_in "Supervisor", with: "My Supervisor"
      fill_in "Supervisor profile", with: "http://supervisor.edu"

      expect { click_on "Create Affiliation" }.
        to change { user.affiliations.count }.by(1)

      expect(page).to have_content("my org")
      expect(page).to have_content("depart")
      expect(page).to have_content("johndoe@uni.edu")
      expect(page).to have_content("12345678")
      expect(page).to have_content("http://my.uni.edu")
      expect(page).to have_content("My Supervisor")
    end

    scenario "I can edit my affiliation" do
      affiliation = create(:affiliation, organization: "my org", user: user)

      visit edit_profile_affiliation_path(affiliation)
      fill_in "Organization", with: "new org"
      click_on "Update Affiliation"
      affiliation.reload

      expect(affiliation.organization).to eq("new org")
    end
  end
end
