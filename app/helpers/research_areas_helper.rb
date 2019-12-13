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
end
