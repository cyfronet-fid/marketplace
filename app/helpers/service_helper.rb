# frozen_string_literal: true

module ServiceHelper
  def print_rating_stars(rating)
    result = ""

    # full stars
    (0...rating.floor).each { result += content_tag(:i, "", class: "fas fa-star fa-lg") }

    # half stars
    result += content_tag(:i, "", class: "fas fa-star-half-alt fa-lg") if rating % 1 != 0

    # empty stars
    (0...(5 - rating.ceil)).each { result += content_tag(:i, "", class: "far fa-star fa-lg") }

    result.html_safe
  end

  def providers_list
    Provider.all
  end

  def dedicated_for_links(service)
    service.target_users.map { |target| link_to(target.name, services_path(target_users: target)) }
  end

  def dedicated_for_text(service)
    service.target_users.map(&:name)
  end

  def scientific_domains(service)
    service.scientific_domains.map { |target| link_to(target.name, services_path(scientific_domains: target)) }
  end

  def scientific_domains_text(service)
    service.scientific_domains.map(&:name)
  end

  def resource_organisation(service, highlights = nil, preview: false)
    target = service.resource_organisation
    preview_options = preview ? { "data-target": "preview.link" } : {}
    link_to_unless(
      target.deleted? || target.draft?,
      highlighted_for(:resource_organisation_name, service, highlights),
      provider_path(target),
      preview_options
    )
  end

  def resource_organisation_pid(service)
    service.resource_organisation.pid
  end

  def resource_organisation_text(service)
    service.resource_organisation.name
  end

  def resource_organisation_and_providers(service)
    service.resource_organisation_and_providers.map { |target| link_to(target.name, provider_path(target)) }
  end

  def resource_organisation_and_providers_text(service)
    service.resource_organisation_and_providers.map(&:name)
  end

  def providers(service, highlights = nil, preview: false)
    highlighted = highlights.present? ? sanitize(highlights[:provider_names])&.to_str : ""
    preview_options = preview ? { "data-target": "preview.link" } : {}
    service
      .providers
      .reject(&:blank?)
      .reject(&:deleted?)
      .reject { |p| p == service.resource_organisation }
      .uniq
      .map do |target|
        if highlighted.present? && highlighted.strip == target.name.strip
          link_to_unless target.deleted? || target.draft?,
                         highlights[:provider_names].html_safe,
                         provider_path(target),
                         preview_options
        else
          link_to_unless target.deleted? || target.draft?, target.name, provider_path(target), preview_options
        end
      end
  end

  def providers_text(service)
    service.providers.reject(&:blank?).reject { |p| p == service.resource_organisation }.map(&:name)
  end

  def filtered_offers(offers)
    params[:service_type] && offers ? offers.each.select { |o| o.first["offer_type"] == params[:service_type] } : offers
  end

  def map_view_to_order_type(service_or_offer)
    service_or_offer.external? ? "external" : service_or_offer.order_type
  end

  def order_type(service)
    types = ([service&.order_type] + service&.offers&.published&.map(&:order_type)).compact.uniq
    types.size > 1 ? "various" : service&.order_type || "other"
  end

  def highlighted_for(field, model, highlights)
    highlights&.dig(field)&.html_safe || model.send(field)
  end

  def data_for_map(geographical_availabilities)
    countries = []
    geographical_availabilities.each do |place|
      co = []
      co = Country.countries_for_region(place&.name) if place
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

  def any_non_european?(countries)
    (countries - Country.countries_for_region("Europe").map(&:alpha2)).present?
  end

  def trl_description_text(service)
    service.trl.first.description
  end

  def new_offer_link(service, controller_name)
    if controller_name == "ordering_configurations"
      new_service_ordering_configuration_offer_path(service)
    else
      new_backoffice_service_offer_path(service)
    end
  end

  def edit_offer_link(service, offer, controller_name)
    case controller_name
    when "ordering_configurations"
      edit_service_ordering_configuration_offer_path(service, offer, from: params[:from])
    when "services"
      edit_backoffice_service_offer_path(service, offer)
    end
  end

  def get_only_regions(locations)
    Country.regions & locations
  end

  def get_only_countries(locations)
    locations.reject { |c| Country.regions.include? c }
  end
end
