# frozen_string_literal: true

module ScientificDomainsHelper
  def grouped_scientific_domains
    result = []
    ScientificDomain.arrange
                    .each { |k, v| group_scientific_domains!(result, "/", k, v) }

    result.each_with_object({}) do |record, acc|
      k, v = record
      acc[k] ||= []
      acc[k] << v
    end.map { |k, v| [k, v] }.sort_by(&:first)
  end

  private

  def group_scientific_domains!(result, current_path, key, values)
    if values.size.positive?
      new_current_path = "#{current_path}#{key.name}/"
      values
        .each { |k, v| group_scientific_domains!(result, new_current_path, k, v) }
    else
      result << [current_path, key]
    end
  end
end
