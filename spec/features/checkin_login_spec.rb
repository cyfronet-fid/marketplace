# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Checkin authentication", end_user_frontend: true do
  include OmniauthHelper

  scenario "login" do
    user = create(:user)

    checkin_sign_in_as(user)

    expect(page.body).to have_content "Successfully authenticated"
  end
end
