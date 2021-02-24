# frozen_string_literal: true

module ServiceHelper
  def print_rating_stars(rating)
    result = ""
    # full stars
    (0...rating.floor).each { result += content_tag(:i, "", class: "fas fa-star fa-lg") }

    # half stars
    result += content_tag(:i, "", class: "fas fa-star-half-alt fa-lg") if rating % 1 != 0

    # empty stars
    (0...5 - rating.ceil).each { result += content_tag(:i, "", class: "far fa-star fa-lg") }

    result.html_safe
  end

  def get_providers_list
    Provider.all
  end

  def any_present?(record, *fields)
    fields.map { |f| record.send(f) }.any? { |v| v.present? }
  end

  def get_terms_and_condition_hint_text(service)
    "You are about to order #{service.name} service. Please accept " \
      "#{link_to service.name, service.terms_of_use_url} terms and conditions to proceed.".html_safe
  end

  def dedicated_for_links(service)
    service.target_users.map { |target| link_to(target.name, services_path(target_users: target)) }
  end

  def dedicated_for_text(service)
    service.target_users.map { |target| target.name }
  end

  def scientific_domains(service)
    service.scientific_domains.map { |target| link_to(target.name, services_path(scientific_domains: target)) }
  end

  def field_tree(service, field)
    parents = service.send(field).map { |f| f.parent.blank? ? f : f.parent }
    Hash[parents.map { |parent| [parent.name, (parent.children & service.send(field)).map(&:name)] } ]
  end

  def scientific_domains_text(service)
    service.scientific_domains.map { |target| target.name }
  end

  def resource_organisation(service)
    target = service.resource_organisation
    link_to(target.name, provider_path(target))
  end

  def resource_organisation_text(service)
    service.resource_organisation.name
  end

  def resource_organisation_and_providers(service)
    service.resource_organisation_and_providers.map { |target| link_to(target.name, provider_path(target)) }
  end

  def resource_organisation_and_providers_text(service)
    service.resource_organisation_and_providers.map { |target| target.name }
  end

  def providers(service)
    service.providers.map { |target| link_to(target.name, provider_path(target)) }
  end

  def providers_text(service)
    service.providers.map { |target| target.name }
  end

  def filtered_offers(offers)
    if params[:service_type] && offers
      offers&.each.reject { |o| o.first.dig("offer_type") != params[:service_type] }
    else
      offers
    end
  end

  def map_view_to_order_type(service_or_offer)
    if service_or_offer.external
      "external"
    else
      service_or_offer.order_type
    end
  end

  def order_type(service)
    types = service&.offers.map { |o| o.order_type }.uniq
    if types.size > 1
      "various"
    else
      service&.order_type || "other"
    end
  end

  def highlighted_for(field, model, highlights)
    highlights&.dig(field)&.html_safe || model.send(field)
  end

  def service_logo(service, classes = "align-self-center mr-4 float-left img-responsive", resize = "100x67")
    if service.logo.attached? && service.logo.variable?
      image_tag service.logo.variant(resize: resize), class: classes
    else
      image_pack_tag("eosc-img.png", size: resize, class: classes)
    end
  end

  def data_for_map(geographical_availabilities)
    countries = []
    geographical_availabilities.each { |place|
      co = []
      co = Country.countries_for_region(place&.name) if place
      co = [place] if co.empty?
      countries = countries | co if co.any?
    }
    countries.map(&:alpha2).map { |c| [c.downcase, 1] }
  end

  def data_for_region(countries)
    if is_any_non_european(countries) &&
        (countries != ["EO"]) &&
        (countries != ["EU"])
      countries.append("WW")
    end
    countries
  end

  def is_any_non_european(countries)
    (countries -
     Country.countries_for_region("Europe").map(&:alpha2))
      .present?
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
    if controller_name == "ordering_configurations"
      edit_service_ordering_configuration_offer_path(service, offer)
    elsif controller_name == "services"
      edit_backoffice_service_offer_path(service, offer)
    end
  end
end
