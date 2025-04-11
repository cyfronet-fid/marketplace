# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Question about provider", end_user_frontend: true do
  include OmniauthHelper

  let(:provider) { create(:provider) }
  let(:upstream) { build(:eosc_registry_provider_source) }

  before do
    upstream.update!(provider: provider)
    provider.update!(upstream: upstream)
  end

  context "as logged in user" do
    before { checkin_sign_in_as(create(:user)) }

    scenario "I can send question to contact emails", js: true do
      Capybara.page.current_window.resize_to("1600", "1024")

      visit provider_path(provider)

      click_on "Ask provider a question"

      within("#form-modal") { fill_in("provider_question_text", with: "text") }

      expect do
        click_on "SEND"
        expect(page).to have_content("Your message was successfully sent")
      end.to change { ActionMailer::Base.deliveries.count }.by(1)

      expect(Jms::PublishJob).to have_been_enqueued.with(hash_including(message_type: "provider_question"))
    end

    scenario "I cannot send message about service with empty message", js: true do
      Capybara.page.current_window.resize_to("1600", "1024")
      create_list(:public_contact, 2, contactable: provider)

      visit provider_path(provider)

      click_on "Ask provider a question"

      click_on "SEND"

      expect(page).to have_content("cannot be blank")

      expect(Jms::PublishJob).not_to have_been_enqueued.with(hash_including(:message_type))
    end
  end

  context "as not logged in user" do
    scenario "I can send message about provider", js: true do
      Capybara.page.current_window.resize_to("1600", "1024")

      visit provider_path(provider)

      click_on "Ask provider a question"

      within("#form-modal") do
        fill_in("provider_question_author", with: "John Doe")
        fill_in("provider_question_email", with: "john.doe@company.com")
        fill_in("provider_question_text", with: "text")
      end

      expect do
        click_on "SEND"
        expect(page).to have_content("Your message was successfully sent")
      end.to change { ActionMailer::Base.deliveries.count }.by(1)

      expect(Jms::PublishJob).to have_been_enqueued.with(hash_including(message_type: "provider_question"))
    end

    scenario "I cannot send message about provider with empty fields", js: true do
      Capybara.page.current_window.resize_to("1600", "1024")
      create_list(:public_contact, 2, contactable: provider)

      visit provider_path(provider)

      click_on "Ask provider a question"

      click_on "SEND"

      expect(page).to have_content("can't be blank")
      expect(page).to have_content("can't be blank and is not a valid email address")
      expect(page).to have_content("cannot be blank")

      expect(Jms::PublishJob).not_to have_been_enqueued.with(hash_including(:message_type))
    end
  end
end
