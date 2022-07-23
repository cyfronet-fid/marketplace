# frozen_string_literal: true

module CategoriesHelper
  def category_query_params
    params.permit!.reject { |p| %w[action controller category_id utf8].include?(p) }
  end

  def style_indentation_variables(record)
    level = record&.ancestry_depth
    "--pl-level: #{(20 * level) + 20}px;
     --bg-level: #{(26 * level) + 8}px;"
  end
end
