# frozen_string_literal: true

require "rails_helper"

RSpec.describe Filter::ResearchActivity, backend: true do
  context "#options" do
    it "returns tree structure with accumulated count with correct values" do
      root = create(:research_activity)
      child1, child2 = create_list(:research_activity, 2, parent: root)
      unexpected = create_list(:funding_body, 5)

      create(:service, research_activities: [root], funding_bodies: [unexpected.sample])
      create(:service, research_activities: [child1, child2], funding_bodies: unexpected.sample(2))
      create(:service, research_activities: [child2])

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
      parent = create(:research_activity)
      child1, child2 = create_list(:research_activity, 2, parent: parent)
      create(:service, research_activities: [child2])

      params = ActionController::Parameters.new("research_activities" => [child1.id.to_s, parent.id.to_s])

      filter = described_class.new(params: params)
      filter.counters = { child2.id => 1 }

      expect(filter.active_filters).to include(
        ["Research Activities", child1.name, "research_activities" => []],
        ["Research Activities", parent.name, "research_activities" => []]
      )
    end
  end

  context "#constraint" do
    it "use parent and all children when parent is selected" do
      parent = create(:research_activity)
      child = create(:research_activity, parent: parent)
      create(:service)

      filter = described_class.new(params: { "research_activities" => [child.id.to_s] })

      expect(filter.constraint).to eq(research_activities: [child.id])
    end

    it "use only parent and selected children when parent and children is selected" do
      parent = create(:research_activity)
      child1, child2 = create_list(:research_activity, 2, parent: parent)
      create(:service, research_activities: [child2])

      filter = described_class.new(params: { "research_activities" => [parent.id.to_s, child1.id.to_s] })

      expect(filter.constraint).to eq(research_activities: [parent.id, child1.id])
    end
  end
end
