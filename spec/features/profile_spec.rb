# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Profile page", end_user_frontend: true do
  include OmniauthHelper

  let(:user) { create(:user) }

  context "as logged in user" do
    before { checkin_sign_in_as(user) }

    scenario "can be seen by authenticated user" do
      allow(Rails.configuration).to receive(:whitelabel).and_return(true)
      visit root_path

      click_link("Profile", match: :first)

      expect(page.body).to have_text(user.first_name)
      expect(page.body).to have_text(user.last_name)
      expect(page.body).to have_text(user.email)
    end

    scenario "I can edit my profile interests" do
      c1, c2 = create_list(:category, 2)
      sd1, sd2 = create_list(:scientific_domain, 2)

      visit profile_path

      click_link("Edit", match: :first)

      select c1.name, from: "Categories of interests"
      select sd2.name, from: "Scientific domains of interests"

      check "New Service in Category of interest"

      click_on "Save changes"

      within "#profile-information" do
        expect(page).to have_text(c1.name)
        expect(page).to_not have_text(c2.name)

        expect(page).to_not have_text(sd1.name)
        expect(page).to have_text(sd2.name)
      end

      expect(page).to have_text("Category of interests")
      expect(page).to_not have_text("Scientific domain of interests")
    end

    scenario "I can delete my profile information" do
      c = create(:category)
      sd = create(:scientific_domain)
      user.update(categories: [c], scientific_domains: [sd], categories_updates: true, scientific_domains_updates: true)

      visit profile_path

      within "#profile-information" do
        expect(page).to have_text(c.name)
        expect(page).to have_text(sd.name)

        expect(page).to have_text("Category of interests")
        expect(page).to have_text("Scientific domain of interests")
      end

      click_link("Edit", match: :first)

      click_on "Delete"

      expect(page).to have_text("Profile information removed successfully")

      within "#profile-information" do
        expect(page).to_not have_text(c.name)
        expect(page).to_not have_text(sd.name)

        expect(page).to_not have_text("Category of interests")
        expect(page).to_not have_text("Scientific domain of interests")
      end
    end
  end

  scenario "link isn't visible to unauthenticated user" do
    visit root_path

    expect(page.body).to have_no_selector("nav", text: "Profile")
  end
end
