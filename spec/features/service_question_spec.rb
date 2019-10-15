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

    scenario "I can send qestion to contact emails" do
      user1, user2 = create_list(:user, 2)
      service = create(:service, contact_emails: [user1.email, user2.email])

      visit service_path(service)

      find("#modal-show").click

      within("#question-modal") do
        fill_in("service_question_text", with: "my question")
      end

      expect do
        click_on "SEND"
        expect(page).to have_content("Your message was successfully sent")
      end.to change { ActionMailer::Base.deliveries.count }.by(2)
    end

    scenario "I cannot send message about service with empty message", js: true do
      user1, user2 = create_list(:user, 2)
      service = create(:service, contact_emails: [user1.email, user2.email])

      visit service_path(service)

      find("#modal-show").click

      click_on "SEND"

      expect(page).to have_content("Text Question cannot be blank")
    end
  end

  context "as not logged in user" do
    scenario "I can send message about service", js: true do
      user1, user2 = create_list(:user, 2)
      service = create(:service, contact_emails: [user1.email, user2.email])

      visit service_path(service)

      find("#modal-show").click

      within("#question-modal") do
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
      user1, user2 = create_list(:user, 2)
      service = create(:service, contact_emails: [user1.email, user2.email])

      visit service_path(service)

      find("#modal-show").click

      click_on "SEND"

      expect(page).to have_content("Author can't be blank")
      expect(page).to have_content("Email can't be blank and Email is not a valid email address")
      expect(page).to have_content("Text Question cannot be blank")
    end
  end
end
