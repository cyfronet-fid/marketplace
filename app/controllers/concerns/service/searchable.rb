# frozen_string_literal: true

module Service::Searchable
  extend ActiveSupport::Concern

  included do
    include Paginable
  end

  private

    def search(search_scope)
      query_present? ? search_fields(search_scope) : paginate(search_scope)
    end

    def query_present?
      params[:q].present?
    end

    def search_fields(search_scope)
      Service.search params[:q],
                     fields: ["title^10", "description"],
                     operator: "or",
                     where: { id: search_scope.ids },
                     page: params[:page], per_page: per_page
    end
end
