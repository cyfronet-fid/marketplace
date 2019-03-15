# frozen_string_literal: true

class Filter::ResearchArea < Filter
  def initialize(params = {})
    super(params: params.fetch(:params, {}),
          field_name: "research_area", type: :select,
          title: "Research Area")
  end

  private

    def fetch_options
      [["Any", ""]] +
      ApplicationController.helpers.
        ancestry_id_tree(::ResearchArea.all)
    end

    def do_call(services)
      research_area = ::ResearchArea.find_by(id: value)
      if research_area
        ids = [research_area.id] + research_area.descendant_ids
        services.joins(:service_research_areas).
            where(service_research_areas: { research_area_id: ids })
      else
        services
      end
    end
end
