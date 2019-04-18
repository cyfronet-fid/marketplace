# frozen_string_literal: true

require "rails_helper"

RSpec.describe Filter::Platform do
  context "#options" do
    let!(:platform1) { create(:platform) }
    let!(:platform2) { create(:platform) }
    let!(:service1)  { create(:service, platforms: [platform1]) }
    let!(:service2)  { create(:service, platforms: [platform1, platform2]) }
    let!(:category)  { create(:category, services: [service1]) }

    it "returns platforms with services count depending on the category service belongs to" do
      filter = described_class.new(category: category)

      expect(filter.options).to contain_exactly([platform1.name, platform1.id, 1])
    end

    it "returns all platforms with services count if no category is specified" do
      filter = described_class.new

      expect(filter.options).
        to contain_exactly([platform1.name, platform1.id, 2],
                           [platform2.name, platform2.id, 1])
    end
  end

  context "call" do
    it "filters services basing on selected platforms" do
      platform = create(:platform)
      service = create(:service, platforms: [platform])
      _other_service = create(:service)
      filter = described_class.new(params: { "related_platforms" => platform.id.to_s })

      expect(filter.call(Service.all)).to contain_exactly(service)
    end
  end
end
