# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Api docs page" do
  include OmniauthHelper

  context "as a data administrator" do
    let!(:user) { create(:user) }
    let!(:data_administrator) { create(:data_administrator, email: user.email) }

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

      click_link("Authentication", match: :first)
      expect(page).to have_current_path(api_docs_path(subsection: :authentication))
      expect(page).to have_text('curl -H "X-User-Token": [YOUR TOKEN HERE]')

      click_link("Introduction", match: :first)
      expect(page).to have_current_path(api_docs_path(subsection: :introduction))
      expect(page).to have_text("This is the API of the EOSC Marketplace.")
    end

    scenario "I can revoke my token" do
      visit api_docs_path
      click_link("Revoke token")

      user.reload

      expect(user.authentication_token).to eq("revoked")
      expect(page).to have_text("You don't have an authentication token yet.")
      expect(page).to have_link("Generate token")
    end

    scenario "I can revoke and then generate my token" do
      visit api_docs_path

      prev_token = user.authentication_token

      click_link("Revoke token")
      click_link("Generate token")

      user.reload

      expect(user.authentication_token).to_not eq("revoked")
      expect(user.authentication_token).to_not eq(prev_token)

      expect(page).to have_text(user.authentication_token)
      expect(page).to have_link("Revoke token")
    end

    scenario "I can't regenerate valid token" do
      prev_token = user.authentication_token

      rack_test_session_wrapper = Capybara.current_session.driver
      rack_test_session_wrapper.submit :post, api_docs_path, nil

      user.reload

      expect(user.authentication_token).to eq(prev_token)
    end

    scenario "My token persists after signing out" do
      token = user.authentication_token

      click_link("Logout", match: :first)
      click_link("Login", match: :first)

      visit api_docs_path

      expect(page).to have_text(token)
      expect(page).to have_link("Revoke token")

      user.reload

      expect(user.authentication_token).to eq(token)
    end

    scenario "can no longer visit token page after being demoted from data admin" do
      visit api_docs_path
      expect(page).to have_text(user.authentication_token)
      expect(page).to have_link("Revoke token")

      visit root_path
      data_administrator.destroy

      visit api_docs_path

      expect(page.body).to have_text("You are not authorized to see this page")
      expect(page).to have_current_path(root_path)
    end
  end

  context "as a regular user" do
    let!(:user) { create(:user) }
    before { checkin_sign_in_as(user) }

    scenario "I can't see Marketplace API link", skip: "Marketplace API link shouldn't be here for now" do
      visit root_path

      expect(page.body).to have_no_selector("nav", text: "Marketplace API")
    end

    scenario "I can't visit token page" do
      visit api_docs_path

      expect(page.body).to have_text("You are not authorized to see this page")
      expect(page).to have_current_path(root_path)
    end
  end
end
