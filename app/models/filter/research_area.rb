# frozen_string_literal: true

class Filter::ResearchArea < Filter::AncestryMultiselect
  def initialize(params = {})
    super(params: params.fetch(:params, {}),
          field_name: "research_areas", title: "Research Area",
          model: ::ResearchArea, joining_model: ServiceResearchArea,
          index: "research_areas", search: true)
  end
end
