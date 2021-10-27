# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Profile tour" do
  include OmniauthHelper

  let(:user) { create(:user) }

  before { checkin_sign_in_as(user) }

  scenario "should display first step", js: true do
    visit profile_path

    expect(page).to have_selector(".shepherd-content", visible: true)

    expect(find(".shepherd-header")).to have_text("Edit profile")
    expect(find(".shepherd-text")).to have_text("Click on Edit button to start filling your profile interests.")
    expect(find(".shepherd-footer")).to have_text("SKIP TOUR")
    expect(find(".shepherd-footer")).to have_text("Next")
  end
end
