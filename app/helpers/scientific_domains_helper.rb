# frozen_string_literal: true

module ScientificDomainsHelper
  def grouped_scientific_domains
    result = []
    ScientificDomain.arrange.
      each { |k, v| group_scientific_domains!(result, "/", k, v) }

    result.inject({}) do |acc, record|
      k, v = record
      acc[k] ||= []
      acc[k] << v
      acc
    end.map { |k, v| [k, v] }.sort { |v1, v2| v1.first <=> v2.first }
  end

  private
    def group_scientific_domains!(result, current_path, key, values)
      if values.size > 0
        new_current_path = "#{current_path}#{key.name}/"
        values.
          each { |k, v| group_scientific_domains!(result, new_current_path, k, v) }
      else
        result << [current_path, key]
      end
    end
end
