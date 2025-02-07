# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Backoffice", manager_frontend: true do
  include OmniauthHelper

  before { checkin_sign_in_as(user) }

  context "as normal user" do
    let(:user) { create(:user) }

    scenario "I dont see Backoffice link in navbar" do
      visit root_path

      expect(page).to_not have_content("Backoffice")
    end

    scenario "I'm not able to enter into backoffice" do
      visit backoffice_path

      expect(page).to have_content("You are not authorized")
    end
  end

  context "as a service owner" do
    let(:user) { create(:user, roles: [:coordinator]) }

    scenario "I see Backoffice link in navbar" do
      allow(Rails.configuration).to receive(:whitelabel).and_return(true)
      visit root_path

      expect(page).to have_content("Backoffice")
    end

    scenario "I'm able to enter into backoffice" do
      visit backoffice_path

      expect(page).to have_current_path(backoffice_providers_path)
    end
  end

  context "as a service owner" do
    let(:user) do
      create(:user).tap do |user|
        provider = create(:provider, data_administrators: [build(:data_administrator, email: user.email)])
        create(:service, resource_organisation: provider)
      end
    end

    scenario "I see Backoffice link in navbar" do
      allow(Rails.configuration).to receive(:whitelabel).and_return(true)
      visit root_path

      expect(page).to have_content("Backoffice")
    end

    scenario "I'm able to enter into backoffice" do
      visit backoffice_path

      expect(page).to have_current_path(backoffice_services_path)
    end
  end
end
