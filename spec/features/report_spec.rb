# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Reports" do
  include ActiveJob::TestHelper
  include OmniauthHelper

  context "as unlogged user" do
    scenario "I can report an issue" do
      report = build(:report)
      visit root_path
      find("#report-show").click
      within ("#report-modal") do
        fill_in "Name and surname", with: report.author
        fill_in "Email", with: report.email
        fill_in "Describe problem precisely", with: report.text
      end

      expect do
        find("#report-modal-action-btn").click
        expect(page).to have_content("Your report was successfully sent")
      end.to have_received(Report::Register.new(report).call).with(true)
    end

    context "as logged in user" do
      before { checkin_sign_in_as(create(:user)) }

      scenario "i can report an issue" do
        visit root_path
        find("#report-show").click
        within ("#report-modal") do
          fill_in "Describe problem precisely", with: "Test"
        end
        expect do
          find("#report-modal-action-btn").click
          expect(page).to have_content("Your report was successfully sent")
        end
      end
    end
  end
end
