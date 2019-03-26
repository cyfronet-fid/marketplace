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

    scenario "I can create provider with external source" do
      visit backoffice_providers_path
      click_on "New Provider"

      fill_in "Name", with: "My new provider"
      fill_in "provider_sources_attributes_0_eid", with: "12345a"

      expect { click_on "Create Provider" }.
          to change { Provider.count }.by(1)

      expect(page).to have_content("My new provider")
      expect(page).to have_content("eic: 12345a")
    end

    scenario "I can change external id of the provider" do
      provider = create(:provider, name: "Old name")
      external_source = create(:provider_source, eid: "777abc", source_type: "eic", provider: provider)

      visit edit_backoffice_provider_path(provider)

      expect(page).to have_selector("input[value='777abc']")
      fill_in "provider_sources_attributes_0_eid", with: "12345a"
      click_on "Update Provider"
      expect(page).to have_content("eic: 12345a")
    end

    scenario "I can delete external source" do
      provider = create(:provider)
      external_source = create(:provider_source, eid: "777abc", source_type: "eic", provider: provider)

      visit edit_backoffice_provider_path(provider)
      find(:css, "#provider_sources_attributes_0__destroy").set(true)
      expect { click_on "Update Provider" }.to change { ProviderSource.count }.by(-1)

    end
  end
end
