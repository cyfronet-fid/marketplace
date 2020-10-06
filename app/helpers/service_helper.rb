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

  def providers(service)
    service.providers.map { |target| link_to(target.name, services_path(providers: target)) }
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

  def map_view_to_order_type(object)
    if object.external
      "external"
    elsif object.order_type == "order_required"
      "orderable"
    else
      "open_access"
    end
  end

  def order_type(service)
    types = service&.offers.map { |o| o.order_type }.uniq
    if types.size > 1
      "various"
    elsif types.size == 1
      types.first
    else
      service&.order_type || "external"
    end
  end

  def highlighted_for(field, model, highlights)
    highlights&.dig(field)&.html_safe || model.send(field)
  end

  def service_logo(service)
    if service.logo.attached?
      image_tag service.logo.variant(resize: "100x70")
    else
      image_pack_tag "eosc-img.png"
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
end
