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

  def get_ess_link(catalogue)
    if catalogue.pid.present?
      base_url = Rails.configuration.search_service_base_url

      # TODO: Workaround - Find out why ESS doesn't use pid for filtering
      pid = catalogue.pid.end_with?("-catalogue") ? catalogue.pid.split("-catalogue")[0] : catalogue.pid
      base_url + "/search/all_collection?q=*&fq=catalogue:\"#{pid}\""
    else
      catalogue.website
    end
  end
end
