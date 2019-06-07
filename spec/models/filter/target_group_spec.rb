# frozen_string_literal: true

require "rails_helper"

RSpec.describe Filter::TargetGroup do
  context "#options" do
    let!(:target_group1) { create(:target_group) }
    let!(:target_group2) { create(:target_group) }
    let!(:service1)  { create(:service, target_groups: [target_group1]) }
    let!(:service2)  { create(:service, target_groups: [target_group1, target_group2]) }
    let!(:category)  { create(:category, services: [service1]) }
    let!(:counters) { {target_group1.id => 2, target_group2.id => 1} }

    it "returns all target_groups with services count if no category is specified" do
      filter = described_class.new
      filter.counters = counters

      expect(filter.options).
        to contain_exactly({ name: target_group1.name, id: target_group1.id, count: 2 },
                           { name: target_group2.name, id: target_group2.id, count: 1 })
    end
  end

end
