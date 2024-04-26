# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Reports", js: true, end_user_frontend: true do
  include ActiveJob::TestHelper
  include OmniauthHelper

  pending "as unlogged user" do
    scenario "I can report an issue" do
      report = build(:report)
      visit root_path
      click_on "Report a technical problem"
      within("#form-modal") do
        fill_in "Name and surname", with: report.author
        fill_in "Email", with: report.email
        fill_in "Describe problem precisely", with: report.text
      end

      click_on "SEND"
      expect(page).to have_content("Your report was successfully sent")
    end
  end

  pending "as logged in user" do
    before { checkin_sign_in_as(create(:user)) }

    scenario "i can report an issue" do
      visit root_path
      click_on "Report a technical problem"
      within("#form-modal") { fill_in "Describe problem precisely", with: "Test" }
      expect do
        click_on "SEND"
        expect(page).to have_content("Your report was successfully sent")
      end
    end
  end
end
