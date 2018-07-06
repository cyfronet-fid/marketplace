# frozen_string_literal: true

require "rails_helper"

RSpec.describe AffiliationMailer, type: :mailer do
  context "verification" do
    let(:affiliation) { build(:affiliation, token: "secret", user: build(:user)) }
    let(:mail) { described_class.verification(affiliation).deliver_now }

    it "sends verification email to affilication owner" do
      expect { mail }.to change { ActionMailer::Base.deliveries.count }.by(1)
      expect(mail.to).to contain_exactly(affiliation.user.email)
    end

    it "contains verification link" do
      encoded_body = mail.body.encoded

      expect(encoded_body).
        to include(affiliation_confirmations_url(at: "secret"))
    end
  end
end
