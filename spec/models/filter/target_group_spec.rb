# frozen_string_literal: true

require "rails_helper"

RSpec.describe Filter::TargetGroup do
  context "#options" do
    let!(:target_group1) { create(:target_group) }
    let!(:target_group2) { create(:target_group) }
    let!(:service1)  { create(:service, target_groups: [target_group1]) }
    let!(:service2)  { create(:service, target_groups: [target_group1, target_group2]) }
    let!(:category)  { create(:category, services: [service1]) }

    it "returns target_groups with services count depending on the category service belongs to" do
      filter = described_class.new(category: category)

      expect(filter.options).
        to contain_exactly(name: target_group1.name, id: target_group1.id, count: 1)
    end

    it "returns all target_groups with services count if no category is specified" do
      filter = described_class.new

      expect(filter.options).
        to contain_exactly({ name: target_group1.name, id: target_group1.id, count: 2 },
                           { name: target_group2.name, id: target_group2.id, count: 1 })
    end
  end

  context "call" do
    it "filters services basing on selected target_groups" do
      target_group = create(:target_group)
      service = create(:service, target_groups: [target_group])
      _other_service = create(:service)
      filter = described_class.new(params: { "target_groups" => target_group.id.to_s })

      expect(filter.call(Service.all)).to contain_exactly(service)
    end
  end
end
