# frozen_string_literal: true

require "rails_helper"

RSpec.describe Infrastructure::DestroyJob, type: :job do
  before { allow(Infrastructure::Destroy).to receive(:call) }

  context "with a destroyable infrastructure" do
    let(:infrastructure) { create(:infrastructure, :running) }

    it "destroys it" do
      described_class.perform_now(infrastructure.id)
      expect(Infrastructure::Destroy).to have_received(:call).with(infrastructure)
    end
  end

  context "with an infrastructure that cannot be destroyed" do
    let(:infrastructure) { create(:infrastructure, :destroyed) }

    it "does nothing" do
      described_class.perform_now(infrastructure.id)
      expect(Infrastructure::Destroy).not_to have_received(:call)
    end
  end

  context "with a legacy Infrastructure Manager infrastructure" do
    let(:infrastructure) { create(:infrastructure, :running, allocation_id: nil) }

    it "does nothing" do
      described_class.perform_now(infrastructure.id)
      expect(Infrastructure::Destroy).not_to have_received(:call)
    end
  end

  context "with an unknown infrastructure" do
    it "does nothing" do
      described_class.perform_now(0)
      expect(Infrastructure::Destroy).not_to have_received(:call)
    end
  end
end
