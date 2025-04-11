# frozen_string_literal: true

module SearchLinksHelper
  CONFIG = Mp::Application.config_for(:eosc_explore_banner).freeze
  EXTERNAL_SEARCH_ENABLED = Mp::Application.config.enable_external_search

  def external_search_enabled
    EXTERNAL_SEARCH_ENABLED
  end

  def services_filter_link(element, value, filter_name = "tag_list")
    search_base_url = Mp::Application.config.search_service_base_url
    return search_base_url + "/search/service?q=*&fq=#{filter_name}:%22#{value}%22" if external_search_enabled
    filter_name == "tag_list" ? services_path(tag: element) : services_path("#{filter_name}": element)
  end

  def services_array_filter_link(elements, method, filter_name = "guidelines")
    search_base_url = Mp::Application.config.search_service_base_url
    filter_params = elements.map { |e| e.send(method) }.join("%22 OR %22")
    return "#{search_base_url}/search/service?q=*&fq=#{filter_name}:(%22#{filter_params}%22)" if external_search_enabled
    filter_name == "tag_list" ? services_path(tag: elements) : services_path("#{filter_name}": elements.map(&:id))
  end

  def project_add_link(project)
    if external_search_enabled
      link_to _("Add your first service"),
              project_add_external_link,
              class: "btn btn-primary mb-4 pl-5 pr-5 mt-3 text-center"
    else
      link_to _("Add your first service"),
              project_add_path(project),
              class: "btn btn-primary mb-4 pl-5 pr-5 mt-3 text-center",
              "data-turbo-method": :post
    end
  end

  def project_add_external_link
    search_base_url = Mp::Application.config.search_service_base_url
    search_base_url + "/search/all_collection?q=*"
  end

  def resource_organisation_detail_path(service, backoffice)
    link_to service.resource_organisation.name,
            backoffice ? backoffice_provider_path(service.resource_organisation) : service.resource_organisation
  end

  def providers(service, backoffice)
    service
      .providers
      .compact
      .reject(&:deleted?)
      .reject { |p| p == service.resource_organisation }
      .uniq
      .map do |target|
        if backoffice
          link_to target.name, backoffice_provider_path(target)
        else
          link_to target.name, target
        end
      end
  end

  def services_geographical_availabilities_link(service, gcap)
    service.geographical_availabilities_link(gcap)
  end

  def service_resource_organisation(project_item)
    organisation = project_item.service.resource_organisation
    path = project_item.service.organisation_search_link(organisation.name, services_path(providers: organisation.id))
    link_to organisation.name, path
  end

  def service_providers_list(project_item)
    organisation = project_item.service.resource_organisation
    service = project_item.service
    providers =
      project_item
        .service
        .providers
        .reject { |p| p == organisation }
        .map { |p| link_to(p.name, service.provider_search_link(p.name, services_path(providers: p.id))) }
    safe_join(providers, ", ")
  end

  def services_comparison_link(query_params)
    search_base_url = Mp::Application.config.search_service_base_url
    return search_base_url + "/search/service?q=*" if external_search_enabled
    services_path(params: query_params)
  end

  def guideline_link(guideline)
    search_base_url = Mp::Application.config.search_service_base_url
    search_base_url + "/guidelines/" + guideline.eid
  end

  def go_to_search_query_params(controller_params = nil)
    controller_params ||= {}
    query_params_to_pass = %w[return_path search_params from]
    @query_params = request.query_parameters.slice(*query_params_to_pass)
    @query_params[:from] = controller_params[:from] if controller_params[:from].present?
    @query_params
  end

  def matching_tags(tags)
    tags = tags.map(&:downcase)
    permitted = CONFIG[:tags]
    permitted.select { |tag| tags.include?(tag.downcase) }
  end

  def eosc_explore_url(tags)
    URI.parse(
      CONFIG[:base_url] + CONFIG[:search_url] +
        ERB::Util.url_encode("(\"#{matching_tags(tags)&.map { |tag| tag.split("::").last }&.join("\" OR \"")}\")")
    )
  end

  def eosc_explore_datasource_url(datasource)
    URI.parse(CONFIG[:base_url] + CONFIG[:datasource_search_url] + ERB::Util.url_encode("(\"#{datasource.pid}\")"))
  end

  def show_banner?(tags)
    matching_tags(tags).present?
  end
end
