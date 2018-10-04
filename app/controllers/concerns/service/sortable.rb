# frozen_string_literal: true

module Service::Sortable
  extend ActiveSupport::Concern

  private
    def ordering
      if params[:sort].blank?
        return {}
      end

      sort_key = params[:sort]
      sort_options = {}

      if sort_key[0] == "-"
        sort_key = sort_key[1..-1]
        sort_options[sort_key] = :desc
      else
        sort_options[sort_key] = :asc
      end

      sort_options
    end
end
