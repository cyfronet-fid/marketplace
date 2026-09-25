# frozen_string_literal: true

require "rails_helper"

RSpec.describe Provider::Delete::Cascading, :backend do
  let(:provider) { create(:provider) }
  let!(:service) { create(:service, resource_organisation: provider) }

  context "when called with a provider" do
    before { described_class.call(provider) }

    it "deletes a provider that still has published services" do
      expect(provider.reload.status).to eq("deleted")
    end

    it "enqueues deletion of its published services" do
      expect(DeleteJob).to have_been_enqueued.with(service)
    end
  end

  context "when called with a provider pid" do
    before { described_class.call(provider.pid) }

    it "deletes the provider" do
      expect(provider.reload.status).to eq("deleted")
    end
  end
end
