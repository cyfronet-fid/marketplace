# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Question about service" do
  include OmniauthHelper

  scenario "cannot be send when contact emails are empty" do
    service = create(:service)

    visit service_path(service)

    expect(page).to_not have_content "Want to ask a question about this service?"
  end

  context "as logged in user" do
    before { checkin_sign_in_as(create(:user)) }

    scenario "I can send question to contact emails", js: true do
      service = create(:service)
      create_list(:public_contact, 2, contactable: service)

      visit service_path(service)

      click_on "Want to ask a question about this service?"

      within("#ajax-modal") do
        fill_in("service_question_text", with: "text")
      end

      expect do
        click_on "SEND"
        expect(page).to have_content("Your message was successfully sent")
      end.to change { ActionMailer::Base.deliveries.count }.by(2)
    end

    scenario "I cannot send message about service with empty message", js: true do
      service = create(:service)
      create_list(:public_contact, 2, contactable: service)

      visit service_path(service)

      click_on "Want to ask a question about this service?"

      click_on "SEND"

      expect(page).to have_content("Text Question cannot be blank")
    end
  end

  context "as not logged in user" do
    scenario "I can send message about service", js: true do
      service = create(:service)
      create_list(:public_contact, 2, contactable: service)

      visit service_path(service)

      click_on "Want to ask a question about this service?"

      within("#ajax-modal") do
        fill_in("service_question_author", with: "John Doe")
        fill_in("service_question_email", with: "john.doe@company.com")
        fill_in("service_question_text", with: "text")
      end

      expect do
        click_on "SEND"
        expect(page).to have_content("Your message was successfully sent")
      end.to change { ActionMailer::Base.deliveries.count }.by(2)
    end

    scenario "I cannot send message about service with empty fields", js: true do
      service = create(:service)
      create_list(:public_contact, 2, contactable: service)

      visit service_path(service)

      click_on "Want to ask a question about this service?"

      click_on "SEND"

      expect(page).to have_content("Author can't be blank")
      expect(page).to have_content("Email can't be blank and Email is not a valid email address")
      expect(page).to have_content("Text Question cannot be blank")
    end
  end
end
