# frozen_string_literal: true

require "rails_helper"

RSpec.describe Filter::ResearchActivity, :backend do
  it "builds a hierarchical filter for PL research activities" do
    root = create(:research_activity)
    child = create(:research_activity, parent: root)
    service = create(:service, research_activities: [child])
    filter = described_class.new(params: { "research_activities" => [root.id.to_s] })
    filter.counters = { child.id => 1 }

    expect(filter.options).to contain_exactly(
      name: root.name,
      id: root.id,
      count: 0,
      children: [name: child.name, id: child.id, count: 1, children: [], parent_id: root.id.to_s],
      parent_id: nil
    )
    expect(filter.constraint).to eq(research_activities: [root.id, child.id])
    expect(service.research_activities).to contain_exactly(child)
  end
end
