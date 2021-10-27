# frozen_string_literal: true

module CategoriesHelper
  def category_query_params
    params.permit!.reject do |p|
      %w[action controller category_id utf8].include?(p)
    end
  end
end
