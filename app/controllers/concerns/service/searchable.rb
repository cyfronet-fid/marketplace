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

    def filter_rating(services, search_value)
      if search_value.empty?
        return services
      end
      services.where("rating >= ?", search_value)
    end

    def filter_provider(services, search_value)
      if search_value.empty?
        return services
      end
      services.where(provider: search_value)
    end
  end

  include FieldFilterable


  # Add here new fields from filter form (:q is handled separately, as it requires calling of elasticsearch)
  @@searchable_fields = [:location, :provider, :rating]

  private
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
      filtered_services = scope
      @@searchable_fields.each { |field| filtered_services = filter_by_field(filtered_services, field) }
      filtered_services
    end

    def search_ids
      scope.search(params[:q]).records.ids
    end

    def scope
      Service.all
    end
end
