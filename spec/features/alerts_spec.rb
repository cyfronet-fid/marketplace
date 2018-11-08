# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Affiliations" do
  include OmniauthHelper

  let(:user) { create(:user) }


  context "as logged in user" do
    before { checkin_sign_in_as(user) }

    it "shows alert when no active affiliation" do
      visit root_path

      expect(page).to have_content("You don't have active affiliation")
    end

    it "does not shows alert when has active affiliation" do
      create(:affiliation, user: user, status: :active)

      visit root_path

      expect(page).to_not have_content("You don't have active affiliation")
    end
  end

  context "as anonymous user" do
    it "does not shows active affiliation alert" do
      visit root_path

      expect(page).to_not have_content("You don't have active affiliation")
    end
  end
end
