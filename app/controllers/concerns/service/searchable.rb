# frozen_string_literal: true

module Service::Searchable
  extend ActiveSupport::Concern

  private

    def search(search_scope)
      query_present? ? search_fields(search_scope) : search_scope
    end

    def query_present?
      params[:q].present?
    end

    def search_fields(search_scope)
      result = Service.search(params[:q],
                            fields: ["title^10", "description"],
                            operator: "or",
                            where: { id: search_scope.ids })

      # By default, ids are fetched from
      # Elasticsearch and records are fetched from database.
      # For now we need it here to not mixing concerns
      ids = result.map(&:id).to_a
      ids.blank? ? Service.where(id: ids) : Service.where(id: ids).order_by_ids(ids)
    end
end
