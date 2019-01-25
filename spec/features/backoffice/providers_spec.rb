# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Providers in backoffice" do
  include OmniauthHelper

  context "As a service portolio manager" do
    let(:user) { create(:user, roles: [:service_portfolio_manager]) }

    before { checkin_sign_in_as(user) }

    scenario "I can see all providers" do
      create(:provider, name: "p1")
      create(:provider, name: "p2")

      visit backoffice_providers_path

      expect(page).to have_content("p1")
      expect(page).to have_content("p2")
    end

    scenario "I can see provider details" do
      child = create(:provider, name: "my provider")

      visit backoffice_provider_path(child)

      expect(page).to have_content("my provider")
    end

    scenario "I can create new provider" do
      visit backoffice_providers_path
      click_on "New Provider"

      fill_in "Name", with: "My new provider"

      expect { click_on "Create Provider" }.
        to change { Provider.count }.by(1)

      expect(page).to have_content("My new provider")
    end

    scenario "I can edit provider" do
      provider = create(:provider, name: "Old name")

      visit edit_backoffice_provider_path(provider)

      fill_in "Name", with: "New name"
      click_on "Update Provider"

      expect(page).to have_content("New name")
    end
  end
end
