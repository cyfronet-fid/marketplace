# frozen_string_literal: true

require "rails_helper"

RSpec.describe DeleteJob, :backend do
  context "with an offer" do
    let(:offer) { build_stubbed(:offer) }

    before do
      allow(Offer::Delete).to receive(:call)
      described_class.perform_now(offer)
    end

    it "runs the Delete operation of the object's class" do
      expect(Offer::Delete).to have_received(:call).with(offer)
    end
  end

  context "with a datasource" do
    let(:datasource) { build_stubbed(:datasource) }

    before do
      allow(Service::Delete).to receive(:call)
      described_class.perform_now(datasource)
    end

    it "runs Service::Delete" do
      expect(Service::Delete).to have_received(:call).with(datasource)
    end
  end
end
