# frozen_string_literal: true
require "uri"
module PresentableHelper
  ENABLE_EXTERNAL_SEARCH = Rails.configuration.enable_external_search.freeze
  SEARCH_SERVICE_BASE_URL = Rails.configuration.search_service_base_url.freeze

  def data_for_map(geographical_availabilities)
    countries = []
    geographical_availabilities.each do |place|
      co = []
      co = Country.countries_for_region(place&.iso_short_name) if place
      co = [place] if co.empty?
      countries |= co if co.any?
    end
    countries
      .map(&:alpha2)
      .map { |c| [c.downcase, 1] }
      .map { |c| c == ["uk", 1] ? ["gb", 1] : c }
      .map { |c| c == ["el", 1] ? ["gr", 1] : c }
  end

  def data_for_region(countries)
    countries.append("WW") if any_non_european?(countries) && (countries != ["EO"]) && (countries != ["EU"])
    countries
  end

  def any_present?(record, *fields)
    fields.any? { |f| record.send(f).present? }
  end

  def field_tree(record, field)
    parents = record.send(field).map { |f| f.parent.blank? ? f : f.parent }
    parents.to_h { |parent| [parent.name, (parent.children & record.send(field)).map(&:name)] }
  end

  def presentable_logo(object, classes = "align-self-center img-responsive", resize = [100, 67])
    if object.logo.attached? && object.logo.variable?
      image_tag object.logo.variant(resize_to_limit: resize), class: classes
    elsif object.is_a?(Service)
      image_tag("service_logo.svg", resize_to_limit: resize, class: classes)
    else
      image_tag("provider_logo.svg", resize_to_limit: resize, class: classes)
    end
  end

  def search_link_router(object, type = "scientific_domains")
    return external_children_search_link(object, type) if enable_external_search?
    case type
    when "scientific_domains"
      services_path(scientific_domains: [object.to_param] + object.children&.map(&:to_param))
    when "categories"
      object
    end
  end

  def external_children_search_link(object, type)
    if type == "categories"
      suffix = "#{type}:(#{deep_names(object, 2)})"
    else
      suffix = "#{type}:(#{deep_names(object)})"
    end
    "#{search_service_base_url}/search/service?q=*&fq=#{suffix}"
  end

  private

  def any_non_european?(countries)
    (countries - Country.countries_for_region("Europe").map(&:alpha2)).present?
  end

  def deep_names(parent, level = 1, current_parent_name = nil)
    if parent.children.present?
      current = [current_parent_name, parent.name].compact.join(">")
      if level > 1
        parent.children.map { |c| deep_names(c, level - 1, current) }.flatten.reject(&:blank?).join(" OR ")
      else
        parent
          .children
          .select { |c| c.services.published.size.positive? }
          .map { |c| "\"#{CGI.escape(current)}>#{CGI.escape(c.name)}\"" }
          .compact
          .join(" OR ")
      end
    else
      "\"#{CGI.escape(parent.name)}\""
    end
  end

  def enable_external_search?
    ENABLE_EXTERNAL_SEARCH
  end

  def search_service_base_url
    SEARCH_SERVICE_BASE_URL
  end

  def pc_dashboard_link(object)
    Mp::Application.config.providers_dashboard_url + "/dashboard/#{catalogue_pid(object)}/" +
      "#{object.resource_organisation.pid}/datasource-dashboard/#{object.pid}/stats"
  end

  def pc_edit_link(object)
    Mp::Application.config.providers_dashboard_url +
      "/provider/#{object.resource_organisation.pid}/datasource/update/#{object.pid}"
  end
end
