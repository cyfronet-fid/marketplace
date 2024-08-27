# frozen_string_literal: true

module ServiceHelper
  def print_rating_stars(rating)
    result = ""

    # full stars
    (0...rating.floor).each { result += content_tag(:i, "", class: "fas fa-star fa-lg") }

    # half stars
    result += content_tag(:i, "", class: "fas fa-star-half-alt fa-lg") if rating % 1 != 0

    # empty stars
    (0...(5 - rating.ceil)).each { result += content_tag(:i, "", class: "fas fa-star empty-star fa-lg") }

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

  def catalogue_pid(object)
    object.catalogue&.pid || "eosc"
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

  def providers_text(service)
    service.providers.reject(&:blank?).reject { |p| p == service.resource_organisation }.map(&:name).join(", ")
  end

  def filtered_offers(offers)
    params[:service_type] && offers ? offers.each.select { |o| o.first["offer_type"] == params[:service_type] } : offers
  end

  def map_view_to_order_type(service_or_offer)
    service_or_offer.external? ? "external" : service_or_offer.order_type
  end

  def order_type(orderable)
    types = ([orderable&.order_type] + orderable&.offers&.published&.map(&:order_type)).compact.uniq
    types.size > 1 ? "various" : orderable&.order_type || "other"
  end

  def highlighted_for(field, model, highlights)
    highlights&.dig(field)&.html_safe || model.send(field)
  end

  def trl_description_text(service)
    service.trls.first.description
  end

  def new_offer_link(service, controller_name)
    if controller_name == "ordering_configurations"
      new_service_ordering_configuration_offer_path(service)
    else
      new_backoffice_service_offer_path(service)
    end
  end

  def new_bundle_link(service, controller_name)
    if controller_name == "ordering_configurations"
      new_service_ordering_configuration_bundle_path(service)
    else
      new_backoffice_service_bundle_path(service)
    end
  end

  def edit_offer_link(service, offer, controller_name)
    case controller_name
    when "ordering_configurations"
      edit_service_ordering_configuration_offer_path(service, offer, from: params[:from])
    else
      edit_backoffice_service_offer_path(service, offer)
    end
  end

  def edit_bundle_link(service, bundle, controller_name)
    case controller_name
    when "ordering_configuration"
      edit_service_ordering_configuration_bundle_path(service, bundle, from: params[:from])
    else
      edit_backoffice_service_bundle_path(service, bundle)
    end
  end

  def related_services_title
    _("Suggested compatible services")
  end

  def get_only_regions(locations)
    Country.regions & locations
  end

  def get_only_countries(locations)
    locations.reject { |c| Country.regions.include? c }
  end

  def new_offer_prompt
    "<p>#{_("Create an offer for your service to maximise its visibility and usability.")}</p>" +
      "<p>#{_("With specified offers:")}" +
      "<ul><li>#{_("Your service will be searchable in both the service catalog and the offers catalog")}</li>" +
      "<li>#{_("Your service can be ordered directly in the Marketplace")}</li>" +
      "<li>#{_("You can customize your service to attract more users")}</li></ul>"
  end
end
