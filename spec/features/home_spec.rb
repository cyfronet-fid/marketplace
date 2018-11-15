# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Home" do
  include OmniauthHelper

  scenario "searching should go to /services with correct query" do
    visit "/"

    fill_in "q", with: "Something"
    click_on(id: "query-submit")

    expect(page).to have_current_path(services_path, ignore_query: true)
    expect(page).to have_selector("#q[value='Something']")
  end
end
