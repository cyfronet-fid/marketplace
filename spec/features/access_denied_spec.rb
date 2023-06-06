# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Access denied", end_user_frontend: true do
  include OmniauthHelper

  context "After trying to enter an unauthorized resource" do
    let!(:user) { create(:user) }

    before { checkin_sign_in_as(user) }

    scenario "I am being redirected to root_path" do
      visit backoffice_path
      expect(page).to have_current_path(root_path(anchor: ""))
    end

    scenario "with an anchor tag, I am being redirected to root_path without an anchor tag" do
      visit backoffice_path(anchor: "test")
      expect(page).to have_current_path(root_path(anchor: ""))
    end
  end
end
