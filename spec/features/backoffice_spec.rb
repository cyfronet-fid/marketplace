# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Backoffice" do
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
    let(:user) { create(:user, roles: [:service_owner]) }

    scenario "I see Backoffice link in navbar" do
      visit root_path

      expect(page).to have_content("Backoffice")
    end

    scenario "I'm able to enter into backoffice" do
      visit backoffice_path

      expect(page).to have_current_path(backoffice_path)
    end
  end
end
