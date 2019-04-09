# frozen_string_literal: true

require "rails_helper"

RSpec.describe Filter::ResearchArea do
  context "call" do
    it "filters services basing on ranking" do
      research_area = create(:research_area)
      child_research_area = create(:research_area, parent: research_area)
      service = create(:service, research_areas: [research_area])
      child_research_area_service = create(:service, research_areas: [child_research_area])
      create(:service)
      filter = described_class.new(params: { "research_area" => research_area.id.to_s })

      expect(filter.call(Service.all)).
        to contain_exactly(service, child_research_area_service)
    end
  end
end
