# frozen_string_literal: true

require "rails_helper"

RSpec.describe Filter::ResearchArea do
  context "#options" do
    it "returns tree structure with acumulated count" do
      root = create(:research_area)
      child1, child2 = create_list(:research_area, 2, parent: root)

      create(:service, research_areas: [root])
      create(:service, research_areas: [child1, child2])
      create(:service, research_areas: [child2])

      options = subject.options

      expect(options.count).to eq(1)

      first_option = options.first
      expect(first_option[:name]).to eq(root.name)
      expect(first_option[:id]).to eq(root.id)
      expect(first_option[:count]).to eq(3)

      expect(first_option[:children]).to contain_exactly(
        { name: child1.name, id: child1.id, count: 1, children: [] },
        { name: child2.name, id: child2.id, count: 2, children: [] })
    end
  end
  context "#call" do
    it "use parent and all children when parent is selected" do
      parent = create(:research_area)
      child = create(:research_area, parent: parent)
      service = create(:service, research_areas: [parent])
      child_research_area_service = create(:service, research_areas: [child])
      create(:service)

      filter = described_class.new(params: { "research_areas" => [parent.id.to_s] })

      expect(filter.call(Service.all)).
        to contain_exactly(service, child_research_area_service)
    end

    it "use only parent and selected children when parent and children is selected" do
      parent = create(:research_area)
      child1, child2 = create_list(:research_area, 2, parent: parent)
      service = create(:service, research_areas: [parent])
      child_research_area_service = create(:service, research_areas: [child1])
      create(:service, research_areas: [child2])

      filter = described_class.new(params: { "research_areas" => [parent.id.to_s, child1.id.to_s] })

      expect(filter.call(Service.all)).
        to contain_exactly(service, child_research_area_service)
    end
  end
end
