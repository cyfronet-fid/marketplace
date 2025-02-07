# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Platforms in backoffice", manager_frontend: true do
  include OmniauthHelper

  context "As a service portolio manager" do
    let(:user) { create(:user, roles: [:coordinator]) }

    before { checkin_sign_in_as(user) }

    scenario "I can see all platforms" do
      create(:platform, name: "p1")
      create(:platform, name: "p2")

      visit backoffice_other_settings_platforms_path

      expect(page).to have_content("p1")
      expect(page).to have_content("p2")
    end

    scenario "I can see platform details" do
      child = create(:platform, name: "my platform")

      visit backoffice_other_settings_platform_path(child)

      expect(page).to have_content("my platform")
    end

    scenario "I can create new platform" do
      visit backoffice_other_settings_platforms_path
      click_on "Add new Platform"

      fill_in "Name", with: "My new platform"

      expect { click_on "Create Platform" }.to change { Platform.count }.by(1)

      expect(page).to have_content("My new platform")
    end

    scenario "I can edit platform" do
      platform = create(:platform, name: "Old name")

      visit edit_backoffice_other_settings_platform_path(platform)

      fill_in "Name", with: "New name"
      click_on "Update Platform"

      expect(page).to have_content("New name")
    end
  end
end
