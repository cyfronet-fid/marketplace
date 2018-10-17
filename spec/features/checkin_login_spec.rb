# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Checkin authentication" do
  include OmniauthHelper

  scenario "login" do
    user = create(:user)

    checkin_sign_in_as(user)

    expect(page.body).to have_content "Successfully authenticated"
  end

  scenario "creates default project" do
    user = create(:user)

    checkin_sign_in_as(user)

    expect(user.projects.find_by(name: "Services")).to_not be_nil
  end
end
