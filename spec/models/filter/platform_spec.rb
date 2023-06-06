# frozen_string_literal: true

require "rails_helper"

RSpec.describe Filter::Platform, backend: true do
  context "#options" do
    let!(:platform1) { create(:platform) }
    let!(:platform2) { create(:platform) }
    let!(:service1) { create(:service, platforms: [platform1]) }
    let!(:service2) { create(:service, platforms: [platform1, platform2]) }
    let!(:category) { create(:category, services: [service1]) }
    let!(:counters) { { platform1.id => 2, platform2.id => 1 } }

    it "returns all platforms with services count if no category is specified" do
      filter = described_class.new
      filter.counters = counters
      expect(filter.options).to contain_exactly(
        { name: platform1.name, id: platform1.id, count: 2 },
        { name: platform2.name, id: platform2.id, count: 1 }
      )
    end
  end
end
