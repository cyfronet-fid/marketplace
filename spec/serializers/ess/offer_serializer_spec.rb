# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ess::OfferSerializer, :backend do
  let(:offer) { create(:offer) }

  context "when the variant is marketplace" do
    before { allow(Mp::Variant).to receive(:marketplace?).and_return(true) }

    it "serializes the orderable type" do
      expect(described_class.new(offer).as_json[:orderable_type]).to eq("Service")
    end

    it "serializes the orderable id as the service id" do
      expect(described_class.new(offer).as_json[:service_id]).to eq(offer.orderable_id)
    end
  end

  context "when the variant is pl or whitelabel" do
    before { allow(Mp::Variant).to receive(:marketplace?).and_return(false) }

    it "does not serialize the orderable type" do
      expect(described_class.new(offer).as_json).not_to have_key(:orderable_type)
    end

    it "serializes the orderable id as the service id" do
      expect(described_class.new(offer).as_json[:service_id]).to eq(offer.orderable_id)
    end
  end
end
