# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Affiliation confirmation page" do
  include OmniauthHelper

  scenario "shouldn't show the 'no active affiliation' notice if just activated one" do
    user = create(:user)
    affiliation = create(:affiliation, token: "secret", user: user)

    checkin_sign_in_as(user)

    visit root_path

    expect(page).to have_content("An affiliation is required to order a service")

    visit affiliation_confirmations_path(at: "secret")

    affiliation.reload
    expect(affiliation).to be_active
    expect(page).not_to have_content("An affiliation is required to order a service")
  end
end
