# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Question about service", end_user_frontend: true do
  include OmniauthHelper

  let(:service) { create(:service) }
  let(:upstream) { build(:eosc_registry_service_source) }

  before do
    upstream.update!(service: service)
    service.update!(upstream: upstream)
  end

  scenario "cannot be send when contact emails are empty" do
    service.public_contacts = []
    service.save(validate: false)
    visit service_path(service)

    expect(page).to_not have_content "Ask a question about this service?"
  end

  context "as logged in user" do
    before { checkin_sign_in_as(create(:user)) }

    scenario "I can send question to contact emails", js: true do
      Capybara.page.current_window.resize_to("1600", "1024")
      create_list(:public_contact, 2, contactable: service)

      visit service_path(service)

      click_on "Contact provider"

      within("#form-modal") { fill_in("service_question_text", with: "text") }

      expect do
        click_on "SEND"
        sleep(5)
        expect(page.current_path).to eq(service_path(service))
        expect(page).to have_content("Your message was successfully sent")
      end.to change { ActionMailer::Base.deliveries.count }.by(3)

      expect(Jms::PublishJob).to have_been_enqueued.with(hash_including(message_type: "service_question"))
    end

    scenario "I cannot send message about service with empty message", js: true do
      Capybara.page.current_window.resize_to("1600", "1024")
      create_list(:public_contact, 2, contactable: service)

      visit service_path(service)

      click_on "Contact provider"

      click_on "SEND"

      expect(page).to have_content("cannot be blank")

      expect(Jms::PublishJob).not_to have_been_enqueued.with(hash_including(:message_type))
    end
  end

  context "as not logged in user" do
    scenario "I can send message about service", js: true do
      Capybara.page.current_window.resize_to("1600", "1024")
      create_list(:public_contact, 2, contactable: service)

      visit service_path(service)

      click_on "Contact provider"

      within("#form-modal") do
        fill_in("service_question_author", with: "John Doe")
        fill_in("service_question_email", with: "john.doe@company.com")
        fill_in("service_question_text", with: "text")
      end

      expect do
        click_on "SEND"
        sleep(5)
        expect(page.current_path).to eq(service_path(service))
        expect(page).to have_content("Your message was successfully sent")
      end.to change { ActionMailer::Base.deliveries.count }.by(3)

      expect(Jms::PublishJob).to have_been_enqueued.with(hash_including(message_type: "service_question"))
    end

    scenario "I cannot send message about service with empty fields", js: true do
      Capybara.page.current_window.resize_to("1600", "1024")
      create_list(:public_contact, 2, contactable: service)

      visit service_path(service)

      click_on "Contact provider"

      click_on "SEND"

      expect(page).to have_content("can't be blank")
      expect(page).to have_content("can't be blank and is not a valid email address")
      expect(page).to have_content("cannot be blank")

      expect(Jms::PublishJob).not_to have_been_enqueued.with(hash_including(:message_type))
    end
  end
end
