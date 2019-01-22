# frozen_string_literal: true

module ResearchAreasHelper
  def grouped_research_areas
    result = []
    ResearchArea.arrange.
      each { |k, v| group_research_areas!(result, "/", k, v) }

    result.inject({}) do |acc, record|
      k, v = record
      acc[k] ||= []
      acc[k] << v
      acc
    end.map { |k, v| [k, v] }.sort { |v1, v2| v1.first <=> v2.first }
  end

  def research_areas_tree(research_areas)
    create_research_areas_tree(research_areas, ResearchArea.new, 0)
  end

  private

    def group_research_areas!(result, current_path, key, values)
      if values.size > 0
        new_current_path = "#{current_path}#{key.name}/"
        values.
          each { |k, v| group_research_areas!(result, new_current_path, k, v) }
      else
        result << [current_path, key]
      end
    end

    def create_research_areas_tree(research_areas, parent, level)
      research_areas.
          select { |ra| ra.ancestry_depth == level && ra.child_of?(parent) }.
          map do |ra|
        [[indented_name(ra.name, level), ra.id],
          *create_research_areas_tree(research_areas, ra, level + 1)]
      end.
          flatten(1)
    end

    def indented_name(name, level)
      indentation = "&nbsp;&nbsp;" * level
      "#{indentation}#{ERB::Util.html_escape(name)}".html_safe
    end
end
