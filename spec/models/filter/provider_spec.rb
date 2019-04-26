# frozen_string_literal: true

require "rails_helper"

RSpec.describe Filter::Provider do
  context "#options" do
    let!(:provider1) { create(:provider) }
    let!(:provider2) { create(:provider) }
    let!(:service1)  { create(:service, providers: [provider1]) }
    let!(:service2)  { create(:service, providers: [provider1, provider2]) }
    let!(:category)  { create(:category, services: [service1]) }

    it "returns providers with services count depending on the category service belongs to" do
      filter = described_class.new(category: category)

      expect(filter.options).
        to contain_exactly(name: provider1.name, id: provider1.id, count: 1)
    end

    it "returns all providers with services count if no category is specified" do
      filter = described_class.new

      expect(filter.options).
        to contain_exactly({ name: provider1.name, id: provider1.id, count: 2 },
                           { name: provider2.name, id: provider2.id, count: 1 })
    end
  end

  context "call" do
    it "filters services basing on selected provider" do
      provider = create(:provider)
      service = create(:service, providers: [provider])
      _other_service = create(:service)
      filter = described_class.new(params: { "providers" => provider.id.to_s })

      expect(filter.call(Service.all)).to contain_exactly(service)
    end
  end
end
