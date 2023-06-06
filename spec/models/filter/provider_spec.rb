# frozen_string_literal: true

require "rails_helper"

RSpec.describe Filter::Provider, backend: true do
  context "#options" do
    let!(:provider1) { create(:provider) }
    let!(:provider2) { create(:provider) }
    let!(:provider3) { create(:provider) }
    let!(:provider4) { create(:provider) }
    let!(:service1) { create(:service, providers: [provider1], resource_organisation: provider3) }
    let!(:service2) { create(:service, providers: [provider1, provider2], resource_organisation: provider4) }
    let!(:category) { create(:category, services: [service1]) }
    let!(:counters) { { provider1.id => 2, provider2.id => 1 } }

    it "returns all providers with services count if no category is specified" do
      filter = described_class.new
      filter.counters = counters

      expect(filter.options).to contain_exactly(
        { name: provider1.name, id: provider1.id, count: 2 },
        { name: provider2.name, id: provider2.id, count: 1 },
        { name: provider3.name, id: provider3.id, count: 0 },
        { name: provider4.name, id: provider4.id, count: 0 }
      )
    end
  end
end
