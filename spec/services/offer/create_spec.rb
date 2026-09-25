# frozen_string_literal: true

require "rails_helper"

RSpec.describe Offer::Create, :backend do
  let!(:service) { create(:service) }
  let(:offer) { build(:offer, service: service) }

  before do
    allow(Mp::Variant).to receive(:pl?).and_return(pl)
    clear_enqueued_jobs
    described_class.call(offer)
  end

  context "when running as pl" do
    let(:pl) { true }

    it "saves the offer" do
      expect(offer).to be_persisted
    end

    it "pushes the service to ESS after saving the offer" do
      expect(Ess::UpdateJob).to have_been_enqueued.with(hash_including("data_type" => "service"))
    end
  end

  context "when running outside pl" do
    let(:pl) { false }

    it "saves the offer" do
      expect(offer).to be_persisted
    end

    it "does not push the service to ESS" do
      expect(Ess::UpdateJob).not_to have_been_enqueued.with(hash_including("data_type" => "service"))
    end
  end
end
