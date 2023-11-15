# frozen_string_literal: true

require "rails_helper"

RSpec.describe Filter::MarketplaceLocation, backend: true do
  context "#options" do
    it "returns tree structure with accumulated count with correct values" do
      root = create(:marketplace_location)
      child1, child2 = create_list(:marketplace_location, 2, parent: root)
      unexpected = create_list(:funding_body, 5)

      create(:service, marketplace_locations: [root], funding_bodies: [unexpected.sample])
      create(:service, marketplace_locations: [child1, child2], funding_bodies: unexpected.sample(2))
      create(:service, marketplace_locations: [child2])

      counters = { root.id => 1, child1.id => 1, child2.id => 2 }
      subject.counters = counters

      options = subject.options

      expect(options.count).to eq(1)

      first_option = options.first
      expect(first_option[:name]).to eq(root.name)
      expect(first_option[:id]).to eq(root.id)
      expect(first_option[:count]).to eq(1)

      expect(first_option[:children]).to contain_exactly(
        { name: child1.name, id: child1.id, count: 1, children: [], parent_id: root.id.to_s },
        { name: child2.name, id: child2.id, count: 2, children: [], parent_id: root.id.to_s }
      )
    end
  end

  context "#active filters" do
    it "returns correct active filters" do
      parent = create(:marketplace_location)
      child1, child2 = create_list(:marketplace_location, 2, parent: parent)
      create(:service, marketplace_locations: [child2])

      params = ActionController::Parameters.new("marketplace_locations" => [child1.id.to_s, parent.id.to_s])

      filter = described_class.new(params: params)
      filter.counters = { child2.id => 1 }

      expect(filter.active_filters).to include(
        ["Marketplace Locations", child1.name, "marketplace_locations" => []],
        ["Marketplace Locations", parent.name, "marketplace_locations" => []]
      )
    end
  end

  context "#constraint" do
    it "use parent and all children when parent is selected" do
      parent = create(:marketplace_location)
      child = create(:marketplace_location, parent: parent)
      create(:service)

      filter = described_class.new(params: { "marketplace_locations" => [child.id.to_s] })

      expect(filter.constraint).to eq(marketplace_locations: [child.id])
    end

    it "use only parent and selected children when parent and children is selected" do
      parent = create(:marketplace_location)
      child1, child2 = create_list(:marketplace_location, 2, parent: parent)
      create(:service, marketplace_locations: [child2])

      filter = described_class.new(params: { "marketplace_locations" => [parent.id.to_s, child1.id.to_s] })

      expect(filter.constraint).to eq(marketplace_locations: [parent.id, child1.id])
    end
  end
end
