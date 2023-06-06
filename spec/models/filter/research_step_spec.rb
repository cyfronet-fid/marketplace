# frozen_string_literal: true

require "rails_helper"

RSpec.describe Filter::ResearchStep, backend: true do
  context "#options" do
    it "returns tree structure with accumulated count with correct values" do
      root = create(:research_step)
      child1, child2 = create_list(:research_step, 2, parent: root)
      unexpected = create_list(:funding_body, 5)

      create(:service, research_steps: [root], funding_bodies: [unexpected.sample])
      create(:service, research_steps: [child1, child2], funding_bodies: unexpected.sample(2))
      create(:service, research_steps: [child2])

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
      parent = create(:research_step)
      child1, child2 = create_list(:research_step, 2, parent: parent)
      create(:service, research_steps: [child2])

      params = ActionController::Parameters.new("research_steps" => [child1.id.to_s, parent.id.to_s])

      filter = described_class.new(params: params)
      filter.counters = { child2.id => 1 }

      expect(filter.active_filters).to include(
        ["Research steps", child1.name, "research_steps" => []],
        ["Research steps", parent.name, "research_steps" => []]
      )
    end
  end

  context "#constraint" do
    it "use parent and all children when parent is selected" do
      parent = create(:research_step)
      child = create(:research_step, parent: parent)
      create(:service)

      filter = described_class.new(params: { "research_steps" => [child.id.to_s] })

      expect(filter.constraint).to eq(research_steps: [child.id])
    end

    it "use only parent and selected children when parent and children is selected" do
      parent = create(:research_step)
      child1, child2 = create_list(:research_step, 2, parent: parent)
      create(:service, research_steps: [child2])

      filter = described_class.new(params: { "research_steps" => [parent.id.to_s, child1.id.to_s] })

      expect(filter.constraint).to eq(research_steps: [parent.id, child1.id])
    end
  end
end
