# frozen_string_literal: true

module Service::Searchable
  extend ActiveSupport::Concern

  private
    def records
      order params[:q].blank? ? scope : scope.where(id: search_ids)
    end

    def order(elements)
      unless params[:sort] && params[:sort].length > 0
        return elements
      end

      sort_key = params[:sort]
      sort_options = {}

      if sort_key[0] == "-"
        sort_key = sort_key[1..-1]
        sort_options[sort_key] = :desc
      else
        sort_options[sort_key] = :asc
      end

      elements.order(sort_options)
    end

    def search_ids
      Service.search(params[:q]).records.ids
    end

    def scope
      Service.all
    end
end
