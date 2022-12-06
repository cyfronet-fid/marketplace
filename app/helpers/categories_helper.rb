# frozen_string_literal: true

module CategoriesHelper
  def category_query_params
    params.permit!.reject { |p| %w[action controller category_id utf8].include?(p) }
  end

  def style_indentation_variables(record)
    level = record&.ancestry_depth
    "--pl-level: #{(level * 20) + 20}px;
     --bg-level: #{(level * 26) + 8}px;"
  end
end
