# frozen_string_literal: true

require "rails_helper"

RSpec.describe Offer::CreateAsDraft, :backend do
  let(:service) { create(:service) }
  let(:offer) { build(:offer, service: service, status: :draft, name: name, offer_category: nil) }

  before { described_class.call(offer) }

  # A draft skips the validation of the offer: the offer category is mandatory for a published offer.
  context "when the offer has a name" do
    let(:name) { "Draft offer" }

    it "saves the offer" do
      expect(offer).to be_persisted
    end

    it "keeps the offer a draft" do
      expect(offer.reload).to be_draft
    end
  end

  context "when the offer has no name" do
    let(:name) { "" }

    it "does not save the offer" do
      expect(offer).not_to be_persisted
    end

    it "adds an error to the name" do
      expect(offer.errors[:name]).to eq(["can't be blank"])
    end
  end
end
