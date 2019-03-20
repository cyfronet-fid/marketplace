# frozen_string_literal: true

module CategoriesHelper
  def category_query_params
    params.permit!.reject do |p|
      p == "action" || p == "controller" ||
        p == "category_id" || p == "utf8"
    end
  end
end
