# frozen_string_literal: true

module Service::Autocomplete
  extend ActiveSupport::Concern

  def autocomplete
    query =
      Searchkick.search(
        params[:q],
        fields: %w[name offer_name provider_name],
        operator: "or",
        match: :word_middle,
        limit: 10,
        load: false,
        where: {
          _or: [{ service_id: scope.ids }, { provider_id: provider_scope.ids }]
        },
        highlight: {
          multiple: true,
          tag: "<b>"
        },
        models: [Service, Datasource, Offer, Provider],
        model_includes: {
          Service => [:offers],
          Offer => [:service]
        }
      )

    service_titles = Service.where(id: scope.ids).pluck(:id, :name).to_h

    if request.xhr?
      render(
        template: "services/autocomplete/list",
        locals: {
          results: query.with_highlights,
          service_titles: service_titles
        },
        layout: false
      )
    end
  end
end
