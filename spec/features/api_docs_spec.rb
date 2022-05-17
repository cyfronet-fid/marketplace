# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Api docs page" do
  include OmniauthHelper

  context "JS: as a regular user" do
    let!(:user) { create(:user) }

    before { checkin_sign_in_as(user) }

    scenario "I cannot see my token before clicking 'Show token' button and after clicking 'Hide token'", js: true do
      visit api_docs_path

      expect(page).to_not have_text(user.authentication_token)

      find("#toggler").click

      expect(page).to have_text(user.authentication_token)

      find("#toggler").click

      expect(page).to_not have_text(user.authentication_token)
    end

    scenario "I can regenerate my token", js: true do
      prev_token = user.authentication_token

      visit api_docs_path
      click_link("Regenerate token")

      user.reload

      expect(user.authentication_token).to_not eq(prev_token)

      find("#toggler").click

      expect(page).to have_text(user.authentication_token)
      expect(page).to have_link("Regenerate token")
    end

    context "with nil token" do
      before { user.update_column(:authentication_token, nil) }

      scenario "I can generate token", js: true do
        visit api_docs_path
        expect(page).to have_text("You don't have an authentication token yet")
        click_link("Generate token")

        user.reload

        expect(user.authentication_token).to_not be_nil

        find("#toggler").click

        expect(page).to have_text(user.authentication_token)
        expect(page).to have_link("Regenerate token")
      end
    end

    scenario "My token persists after signing out", js: true do
      token = user.authentication_token

      expect(page).to have_content("About the Marketplace")
      expect(page).to have_content("Successfully authenticated from Checkin account.")
      find_link("Logout").click
      expect(page).to have_content("Signed out successfully.")

      find_link("Login").click
      expect(page).to have_content("Successfully authenticated from Checkin account.")

      visit api_docs_path

      expect(page).to have_content("API")
      find("#toggler").click

      expect(page).to_not have_content("********************")
      expect(page).to have_text(token)
      expect(page).to have_link("Regenerate token")

      user.reload

      expect(user.authentication_token).to eq(token)
    end
  end

  context "as a regular user" do
    let!(:user) { create(:user) }

    before { checkin_sign_in_as(user) }

    scenario "I can see Marketplace API link", skip: "Marketplace API link shouldn't be here for now" do
      visit root_path

      click_link("Marketplace API", match: :first)
      expect(page).to have_text(user.authentication_token)
      expect(page).to have_link("Revoke token")
    end

    scenario "I can see see API wiki" do
      visit api_docs_path

      expect(page).to have_text("This is the API of the EOSC Marketplace.")

      click_link("Basic information", match: :first)
      expect(page).to have_current_path(api_docs_path(subsection: :basic_information))
      expect(page).to have_text("curl -H \"X-User-Token: ios_Bg6L1hsvDyvfYK_C\" [...]")

      click_link("Introduction", match: :first)
      expect(page).to have_current_path(api_docs_path(subsection: :introduction))
      expect(page).to have_text("This is the API of the EOSC Marketplace.")
    end
  end

  context "as anonymous user" do
    scenario "I can visit the api_docs page with login prompt" do
      visit api_docs_path

      expect(page).to have_text("API")
      expect(page).to have_text("Log in to access your authentication token.")
      expect(page).to have_link("Log in")
    end
  end
end
