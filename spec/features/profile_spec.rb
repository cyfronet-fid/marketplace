# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Profile page" do
  include OmniauthHelper

  let(:user) { create(:user) }


  context "as logged in user" do
    before { checkin_sign_in_as(user) }

    scenario "can be seen by authenticated user" do
      visit root_path

      click_link("Profile", match: :first)



      expect(page.body).to have_text(user.first_name)
      expect(page.body).to have_text(user.last_name)
      expect(page.body).to have_text(user.email)
    end

    scenario "I can edit my profile interests" do
      c1, c2 = create_list(:category, 2)
      ra1, ra2 =  create_list(:research_area, 2)

      visit profile_path

      click_link("Edit", match: :first)

      select c1.name, from: "Categories of interests"
      select ra2.name, from: "Research areas of interests"

      check "New service in Category of interest"

      click_on "Save changes"

      within "#profile-information" do
        expect(page).to have_text(c1.name)
        expect(page).to_not have_text(c2.name)

        expect(page).to_not have_text(ra1.name)
        expect(page).to have_text(ra2.name)
      end

      expect(page).to have_text("Category of interests")
      expect(page).to_not have_text("Research area of interests")
    end

    scenario "I can delete my profile" do
      visit profile_path

      click_link("Edit", match: :first)

      click_on "Delete"

      expect(page).to have_text("Profile deleted successfully")
      expect(page).to have_text("Login")
    end
  end


  scenario "link isn't visible to unauthenticated user" do
    visit root_path

    expect(page.body).to have_no_selector("nav", text: "Profile")
  end
end
