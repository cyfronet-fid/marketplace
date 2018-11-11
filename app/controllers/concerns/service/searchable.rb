# frozen_string_literal: true

module Service::Searchable
  extend ActiveSupport::Concern

  # Add field filter methods HERE
  # Filter method should have following name and arguments:
  # filter_<field>(services, search_value)
  #
  module FieldFilterable
    extend ActiveSupport::Concern

    def filter_location(services, search_value)
      # TODO filter by parameter
      services
    end

    def filter_dedicated_for(services, search_value)
      services.where("ARRAY[?] && dedicated_for", search_value)
    end

    def filter_rating(services, search_value)
      services.where("rating >= ?", search_value)
    end

    def filter_providers(services, search_value)
      services.joins(:service_providers).group("services.id")
          .where("service_providers.provider_id IN (?)", search_value)
    end

    def filter_research_area(services, search_value)
      services.joins(:service_research_areas).
              where(service_research_areas: { research_area_id: search_value })
    end
  end

  include FieldFilterable

  # Add here new fields from filter form (:q is handled separately, as it requires calling of elasticsearch)
  @@searchable_fields = [:location, :providers, :rating, :research_area, :dedicated_for]

private

  def dedicated_for_options
    [["Researchers", "Researchers"],
     ["VO", "VO"],
     ["Providers", "Providers"],
     ["Research organisations", "Research organisations"],
     ["Business", "Business"],
     ["Other", "Other"]].map do |field|
      [field[0], field[1], Service.where("? = ANY(dedicated_for)", field[1]).count]
    end .select do |element|
      element[2] != 0
    end
  end

  def provider_options
    Provider.select("providers.name, providers.id, COUNT(service_providers.service_id) as service_count")
    .joins(:service_providers)
    .group("providers.id")
    .order(:name).map do |provider|
      [provider.name, provider.id, provider.service_count]
    end
  end

  def rating_options
    [["Any", ""],
     ["★+", "1"],
     ["★★+", "2"],
     ["★★★+", "3"],
     ["★★★★+", "4"],
     ["★★★★★", "5"]]
  end

  def query_present?
    params[:q].present?
  end

  def filters_present?
    @@searchable_fields.any? { |field| params[field] }
  end

  def records
    results = scope

    if filters_present?
      results = services_filtered_by_fields
    end

    query_present? ? results.where(id: search_ids) : results
  end

  def filter_by_field(elements, field)
    self.send("filter_#{field}".to_s, elements, params[field])
  end

  def services_filtered_by_fields
    @@searchable_fields.
        select { |field| params[field].present? }.
        inject(scope) { |filtered_services, field| filter_by_field(filtered_services, field) }
  end

  def search_ids
    scope.search(params[:q]).records.ids
  end

  def scope
    Service.all
  end
end
