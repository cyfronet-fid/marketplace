# frozen_string_literal: true

require "rails_helper"

RSpec.describe ServiceMailer, type: :mailer, backend: true do
  context "verification" do
    let(:recipient) { create(:user) }
    let(:author) { create(:user) }
    let(:service) { create(:service) }
    let(:public_contact) { create(:public_contact, service: service, email: recipient.email) }
    let(:question) do
      Service::Question.new(text: "text message", author: author, email: author.email, service: service)
    end
    let(:mail) do
      described_class.new_question(recipient.email, question.author, question.email, question.text, service).deliver_now
    end

    it "sends verification email to service representative" do
      expect { mail }.to change { ActionMailer::Base.deliveries.count }.by(1)

      expect(mail.to).to contain_exactly(recipient.email)
    end

    it "contains author message link" do
      encoded_body = mail.body.encoded

      expect(encoded_body).to have_content("text message")
    end
  end

  context "publish" do
    let(:user) { create(:user_with_interests) }
    let(:service1) { create(:service, scientific_domains: user.scientific_domains) }
    let(:service2) { create(:service, categories: user.categories) }
    let(:new_service_mail) do
      described_class.new_service(service1, user.categories, user.scientific_domains, user.email).deliver_now
    end

    it "sends email to interested users" do
      expect { new_service_mail }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end
  end
end
