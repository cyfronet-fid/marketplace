# frozen_string_literal: true

require "rails_helper"

RSpec.describe Provider::Question::Deliver do
  describe "#call" do
    it "sends questions to provider public contact emails" do
      provider = build(:provider, public_contact_emails: %w[first@example.org second@example.org])
      message_delivery = instance_double(ActionMailer::MessageDelivery, deliver_later: true)
      question =
        Provider::Question.new(provider: provider, author: "Jane Doe", email: "jane@example.org", text: "Question text")

      allow(ProviderMailer).to receive(:new_question).and_return(message_delivery)

      described_class.new(question).call

      expect(ProviderMailer).to have_received(:new_question).with(
        "first@example.org",
        "Jane Doe",
        "jane@example.org",
        "Question text",
        provider
      )
      expect(ProviderMailer).to have_received(:new_question).with(
        "second@example.org",
        "Jane Doe",
        "jane@example.org",
        "Question text",
        provider
      )
      expect(message_delivery).to have_received(:deliver_later).twice
    end
  end
end
