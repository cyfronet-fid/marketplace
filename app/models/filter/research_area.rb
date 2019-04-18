# frozen_string_literal: true

class Filter::ResearchArea < Filter
  def initialize(params = {})
    super(params: params.fetch(:params, {}),
          field_name: "research_areas", type: :ancestry_multiselect,
          title: "Research Area")
  end

  private

    def fetch_options
      create_ancestry_tree(::ResearchArea.arrange)
    end

    def create_ancestry_tree(arranged)
      arranged.map do |record, children|
        {
          name: record.name,
          id: record.id,
          count: (grouped_services[record.id] | children_services(children)).size,
          children: create_ancestry_tree(children)
        }
      end
    end

    def children_services(arranged)
      arranged.inject(Set.new) do |s, (record, children)|
        s | grouped_services[record.id] | children_services(children)
      end
    end

    def grouped_services
      @grouped_services ||=
        ServiceResearchArea.pluck(:research_area_id, :service_id).
          inject(Hash.new { |h, k| h[k] = Set.new }) { |h, (k, v)| h[k] << v; h }
    end

    def do_call(services)
      if research_area_ids.size.positive?
        services.joins(:service_research_areas).
            where(service_research_areas: { research_area_id: research_area_ids })
      else
        services
      end
    end

    def research_area_ids
      @research_area_ids ||= begin
        research_areas = ::ResearchArea.where(id: values)
        grouped = research_areas.group_by { |ra| parent?(ra, research_areas) }
        (
          (grouped[true]&.map(&:id) || []) +
          (grouped[false]&.map { |ra| [ra.id] + ra.descendant_ids } || [])
        ).flatten
      end
    end

    def parent?(record, selected)
      selected.any? { |s| record.parent_of?(s) }
    end
end
