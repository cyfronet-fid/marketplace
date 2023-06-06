# frozen_string_literal: true

require "rails_helper"

RSpec.describe Filter::ScientificDomain, backend: true do
  context "#options" do
    it "returns tree structure with accumulated count" do
      root = create(:scientific_domain)
      child1, child2 = create_list(:scientific_domain, 2, parent: root)

      create(:service, scientific_domains: [root])
      create(:service, scientific_domains: [child1, child2])
      create(:service, scientific_domains: [child2])

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
      parent = create(:scientific_domain)
      child1, child2 = create_list(:scientific_domain, 2, parent: parent)
      create(:service, scientific_domains: [child2])

      params = ActionController::Parameters.new("scientific_domains" => [child1.id.to_s, parent.id.to_s])

      filter = described_class.new(params: params)
      filter.counters = { child2.id => 1 }

      expect(filter.active_filters).to include(
        ["Scientific Domains", child1.name, "scientific_domains" => []],
        ["Scientific Domains", parent.name, "scientific_domains" => []]
      )
    end
  end

  context "#constraint" do
    it "use parent and all children when parent is selected" do
      parent = create(:scientific_domain)
      child = create(:scientific_domain, parent: parent)
      create(:service)

      filter = described_class.new(params: { "scientific_domains" => [child.id.to_s] })

      expect(filter.constraint).to eq(scientific_domains: [child.id])
    end

    it "use only parent and selected children when parent and children is selected" do
      parent = create(:scientific_domain)
      child1, child2 = create_list(:scientific_domain, 2, parent: parent)
      create(:service, scientific_domains: [child2])

      filter = described_class.new(params: { "scientific_domains" => [parent.id.to_s, child1.id.to_s] })

      expect(filter.constraint).to eq(scientific_domains: [parent.id, child1.id])
    end
  end
end
