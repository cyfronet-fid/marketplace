# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Parameters in backoffice", manager_frontend: true do
  include OmniauthHelper

  context "As a service portolio manager" do
    let(:user) { create(:user, roles: [:coordinator]) }
    let(:service) { create(:service, offers: [create(:offer)]) }

    before { checkin_sign_in_as(user) }

    scenario "I cannot add invalid multiselect parameter", js: true, skip: "New Offer Wizard" do
      visit edit_backoffice_service_offer_path(service, service.offers.first)

      find("li", text: "Multiselect").click
      find("#attributes-list-button").first("svg").click

      within("div.card-text") do
        fill_in "Name", with: "new multiselect parameter"
        fill_in "Hint", with: "test"
        fill_in "Unit", with: "days"
        select "string", from: "Value type"
        fill_in "Min", with: 0
        fill_in "Max", with: 5
      end

      click_on "Update Offer"

      expect(page).to have_text("can't be blank")
      expect(page).to have_text("must be greater than 0")
    end

    scenario "I cannot set min < 1 and max values greater than values size", js: true, skip: "New Offer Wizard" do
      offer = service.offers.first
      offer.update(parameters: [build(:multiselect_parameter)])

      visit edit_backoffice_service_offer_path(service, offer)
      click_on "Offer Parameters"
      within("div.card-text") do
        fill_in "Name", with: "new multiselect parameter"
        fill_in "Hint", with: "test"
        fill_in "Unit", with: "days"
        select "string", from: "Value type"
        fill_in "Min", with: 0
        fill_in "Max", with: 5
      end

      click_on "Update Offer"

      expect(page).to have_text("Min must be greater than 0")
      expect(page).to have_text("Max must be less than or equal to 4")
    end
  end
end
