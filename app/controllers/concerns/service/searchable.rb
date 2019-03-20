# frozen_string_literal: true

module Service::Searchable
  extend ActiveSupport::Concern

  private

    def search(search_scope)
      query_present? ? search_scope.where(id: search_ids(search_scope)) : search_scope
    end

    def query_present?
      params[:q].present?
    end

    def search_ids(search_scope)
      search_scope.search(params[:q]).records.ids
    end
end
