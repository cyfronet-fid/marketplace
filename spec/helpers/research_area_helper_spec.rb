# frozen_string_literal: true

require "rails_helper"

RSpec.describe ResearchAreasHelper, type: :helper do
  context "#grouped_research_area" do
    it "groups research areas" do
      root1, root2 = create_list(:research_area, 2)
      leaf1, leaf2 = create_list(:research_area, 2, parent: root1)

      groupped = grouped_research_areas

      expect(groupped[0]).to eq(["/", [root2]])
      expect(groupped[1]).to eq(["/#{root1.name}/", [leaf1, leaf2]])
    end
  end
end
