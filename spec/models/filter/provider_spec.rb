# frozen_string_literal: true

require "rails_helper"

RSpec.describe Filter::Provider do
  context "#options" do
    let!(:provider1) { create(:provider) }
    let!(:provider2) { create(:provider) }
    let!(:service1)  { create(:service, providers: [provider1]) }
    let!(:service2)  { create(:service, providers: [provider1, provider2]) }
    let!(:category)  { create(:category, services: [service1]) }
    let!(:counters) { { provider1.id => 2, provider2.id => 1 } }

    it "returns all providers with services count if no category is specified" do
      filter = described_class.new
      filter.counters = counters

      expect(filter.options).
        to contain_exactly({ name: provider1.name, id: provider1.id, count: 2 },
                           { name: provider2.name, id: provider2.id, count: 1 })
    end
  end
end
