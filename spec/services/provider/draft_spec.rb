# frozen_string_literal: true

require "rails_helper"

RSpec.describe Provider::Draft, :backend do
  context "when provider is persisted" do
    let(:provider) { create(:provider) }

    before { described_class.call(provider) }

    it "sets the status to draft" do
      expect(provider.reload).to be_draft
    end
  end

  context "when provider is new, invalid and has no pid" do
    let(:provider) { Provider.new(name: "Draft provider") }

    before { described_class.call(provider) }

    it "persists the provider" do
      expect(provider).to be_persisted
    end

    it "persists a generated pid" do
      expect(provider.reload.pid).to be_present
    end

    it "sets the status to draft" do
      expect(provider.reload).to be_draft
    end
  end
end
