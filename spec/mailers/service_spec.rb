# frozen_string_literal: true

require "rails_helper"

RSpec.describe ServiceMailer, type: :mailer do
  context "verification" do
    let(:recipient) { create(:user) }
    let(:author) { create(:user) }
    let(:service) { build(:service, contact_emails: recipient.email) }
    let(:question) { Service::Question.new(text: "text message",
                                           author: author,
                                           email: author.email,
                                           service: service) }
    let(:mail) { described_class.new_question(recipient.email, question,
                                              service).deliver_now }

    it "sends verification email to service representative" do
      expect { mail }.to change { ActionMailer::Base.deliveries.count }.by(1)

      expect(mail.to).to contain_exactly(recipient.email)
    end

    it "contains author message link" do
      encoded_body = mail.body.encoded

      expect(encoded_body).to have_content("text message")
    end
  end
end
