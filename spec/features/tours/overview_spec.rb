# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Overview tour", end_user_frontend: true do
  context "with several services" do
    before do
      create(:service, name: "a", status: :draft)
      create(:service, name: "b", status: :deleted)
      create(:service, name: "z", status: :published)
      @first_service = create(:service, name: "c", status: :errored)
    end

    scenario "should navigate to first service when advancing to last part of tour", js: true, skip: true do
      visit services_path(tour: "overview")

      click_on "Next"
      click_on "Next"
      click_on "Next"
      click_on "Next"
      click_on "Next"

      expect(page).to have_current_path(service_path(@first_service, tour: "overview"))
    end
  end
end
