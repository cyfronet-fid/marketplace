# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Profile page" do
  include OmniauthHelper

  scenario "can be seen by authenticated user" do
    user = create(:user)

    checkin_sign_in_as(user)

    click_link("Profile", match: :first)

    expect(page.body).to have_text(user.first_name)
    expect(page.body).to have_text(user.last_name)
    expect(page.body).to have_text(user.email)
  end

  scenario "link isn't visible to unauthenticated user" do
    visit root_path

    expect(page.body).to have_no_selector("nav", text: "Profile")
  end
end
