# frozen_string_literal: true

module Service::Searchable
  extend ActiveSupport::Concern

  # Add field filter methods HERE
  # Filter method should have following name and arguments:
  # filter_<field>(services, search_value)
  #
  module FieldFilterable
    extend ActiveSupport::Concern

    def filter_related_platforms(services, search_value)
      @filter_related_platforms ||= services.joins(:service_related_platforms).group("services.id").
          where("service_related_platforms.platform_id IN (?)", search_value)
    end

    def options_related_platforms(category = nil)
      @options_related_platforms ||=
      begin
        query = Platform.select("platforms.name, platforms.id, COUNT(services.id) as service_count")

        if category.nil?
          query = query.joins(:services)
        else
          query = query.joins(:categories).where("categories.id = ?", category.id)
        end

        query.group("platforms.id")
            .order(:name)
            .map { |provider| [provider.name, provider.id, provider.service_count] }
      end
    end

    def filter_location(services, search_value)
      @filter_location ||= services
    end

    def options_location
      @options_location ||= []
    end

    def filter_target_groups(services, search_value)
      @filter_target_groups ||= services.joins(:service_target_groups).
          where("service_target_groups.target_group_id IN (?)", search_value)
    end

    def options_target_groups(category = nil)
      @options_target_groups ||= begin
        query = TargetGroup.select("target_groups.name, target_groups.id, count(services.id) as service_count")

        if category.nil?
          query = query.joins(:services)
        else
          query = query.joins(:categories).where("categories.id = ?", category.id)
        end

        query.group("target_groups.id")
            .order(:name)
            .map { |target_group| [target_group.name, target_group.id, target_group.service_count] }
      end
    end

    def filter_rating(services, search_value)
      @filter_rating ||= services.where("rating >= ?", search_value)
    end

    def options_rating(category = nil)
      [["Any", ""],
       ["★+", "1"],
       ["★★+", "2"],
       ["★★★+", "3"],
       ["★★★★+", "4"],
       ["★★★★★", "5"]]
    end

    def filter_providers(services, search_value)
      @filter_providers ||=
        services.joins(:service_providers).group("services.id")
            .where("service_providers.provider_id IN (?)", search_value)
    end

    def options_providers(category = nil)
      @options_providers ||= begin
        query = Provider.select("providers.name, providers.id, count(service_providers.service_id) as service_count")

        if category.nil?
          query = query.joins(:services)
        else
          query = query.joins(:categories).where("categories.id = ?", category.id)
        end

        query.group("providers.id")
            .order(:name)
            .map { |provider| [provider.name, provider.id, provider.service_count] }
      end
    end

    def filter_research_area(services, search_value)
      @research_area ||= begin
        research_area = ResearchArea.find_by(id: search_value)
        if research_area.nil?
          return nil
        end
        ids = [research_area.id] + research_area.descendant_ids
        services.joins(:service_research_areas).
            where(service_research_areas: { research_area_id: ids })
      end
    end

    def options_research_area
      ResearchArea.all
    end

    def filter_tag(services, tags)
      services.tagged_with(tags)
    end

    def options_tag
      ActsAsTaggableOn::Tag.all.
          map { |t| [t.name, t.name] }.
          sort { |x, y| x[0] <=> y[0] }
    end
  end

  def filters_on?
    searchable_fields.any? { |f| params[f].present? }
  end

  include FieldFilterable

private

  def records
    active_searchable_fields.
        inject(search_scope) { |filtered_services, field| filter_by_field(filtered_services, field) }
  end

  def searchable_fields
    FieldFilterable.public_instance_methods.
        map(&:to_s).
        select { |m| m.start_with?("filter_") }.
        map { |m| m.delete_prefix("filter_") }
  end

  def filter_by_field(elements, field)
    @filter_by_field ||= self.send("filter_#{field}", elements, params[field])
  end

  def search_scope
    query_present? ? scope.where(id: search_ids) : scope
  end

  def query_present?
    params[:q].present?
  end

  def search_ids
    scope.search(params[:q]).records.ids
  end

  def scope
    policy_scope(Service).with_attached_logo
  end

  def active_searchable_fields
    @active_searchable_fields ||= searchable_fields.select { |field| params[field].present? }
  end

  def active_filters
    @active_filters ||= active_searchable_fields
        .map { |field| params[field].is_a?(Array) ? [field, params[field]] : [field, [params[field]]] }
        .map do |field, field_params|
          field_params.map do |p|
            [field, self.send("options_#{field}").find do |name, id, count|
              p == id.to_s
            end]
          end
        end
        .flatten(1)
        .reject { |field, options| options.nil? }
        .map { |field, options| [field, options[0], options[1], options[2]] }
        .map do |field, name, id, count|
      p = params.permit!.to_h
      out_params =
          if params[field].is_a?(Array)
            p[field].delete(id.to_s)
            p
          else
            p.except(field)
          end
      [name, out_params]
    end
  end
end
