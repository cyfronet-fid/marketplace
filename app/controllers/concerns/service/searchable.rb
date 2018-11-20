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
      services.joins(:service_related_platforms).group("services.id").
          where("service_related_platforms.platform_id IN (?)", search_value)
    end

    def filter_location(services, search_value)
      # TODO filter by parameter
      services
    end

    def filter_dedicated_for(services, search_value)
      services.where("ARRAY[?]::varchar[] && dedicated_for", search_value)
    end

    def filter_rating(services, search_value)
      services.where("rating >= ?", search_value)
    end

    def filter_providers(services, search_value)
      services.joins(:service_providers).group("services.id")
          .where("service_providers.provider_id IN (?)", search_value)
    end

    def filter_research_area(services, search_value)
      research_area = ResearchArea.find_by(id: search_value)
      if research_area
        ids = [research_area.id] + research_area.descendant_ids
        services.joins(:service_research_areas).
            where(service_research_areas: { research_area_id: ids })
      end
    end

    def filter_tag(services, tags)
      services.tagged_with(tags)
    end

    def filters_on?
      searchable_fields.any? { |f| params[f].present? }
    end
  end


  include FieldFilterable

private

  def research_areas
    research_areas_tree(ResearchArea.all, ResearchArea.new, 0)
  end

  def research_areas_tree(research_areas, parent, level)
    research_areas.
      select { |ra| ra.ancestry_depth == level && ra.child_of?(parent) }.
      map do |ra|
        [[indented_name(ra.name, level), ra.id],
         *research_areas_tree(research_areas, ra, level + 1)]
      end.
      flatten(1)
  end

  def indented_name(name, level)
    indentation = "&nbsp;&nbsp;" * level
    "#{indentation}#{ERB::Util.html_escape(name)}".html_safe
  end

  def dedicated_for_options(category = nil)
    [["Researchers", "Researchers"],
     ["Research groups", "Research groups"],
     ["Providers", "Providers"],
     ["Research organisations", "Research organisations"],
     ["Business", "Business"],
     ["Other", "Other"]].map do |field|
      query = Service.joins(:categories).where("? = ANY(dedicated_for)", field[1])

      unless category.nil?
        query = query.where("categories.id = ?", category.id)
      end
      [field[0], field[1], query.count]
    end.select do |element|
      element[2] != 0
    end
  end

  def provider_options(category = nil)
    query = Provider.select("providers.name, providers.id, COUNT(service_providers.service_id) as service_count")
                .joins(:categories)

    unless category.nil?
      query = query.where("categories.id = ?", category.id)
    end

    query.group("providers.id")
        .order(:name)
        .map { |provider| [provider.name, provider.id, provider.service_count] }
  end

  def rating_options(category = nil)
    [["Any", ""],
     ["★+", "1"],
     ["★★+", "2"],
     ["★★★+", "3"],
     ["★★★★+", "4"],
     ["★★★★★", "5"]]
  end

  def related_platform_options(category = nil)
    query = Platform.select("platforms.name, platforms.id, COUNT(services.id) as service_count")
        .joins(:categories)
    unless category.nil?
      query = query.where("categories.id = ?", category.id)
    end

    query.group("platforms.id")
         .order(:name)
         .map { |provider| [provider.name, provider.id, provider.service_count] }
  end

  def tag_options
    ActsAsTaggableOn::Tag.all.
      map { |t| [t.name, t.name] }.
      sort { |x, y| x[0] <=> y[0] }
  end

  def records
    searchable_fields.
        select { |field| params[field].present? }.
        inject(search_scope) { |filtered_services, field| filter_by_field(filtered_services, field) }
  end

  def searchable_fields
    FieldFilterable.public_instance_methods.
        map(&:to_s).
        select { |m| m.start_with?("filter_") }.
        map { |m| m.delete_prefix("filter_") }
  end

  def filter_by_field(elements, field)
    self.send("filter_#{field}", elements, params[field])
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
end
