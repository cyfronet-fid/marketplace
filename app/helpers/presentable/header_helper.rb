# frozen_string_literal: true

module Presentable::HeaderHelper
  def service_opinions_link(service, preview)
    count = service.service_opinion_count
    link_to n_("(%{n} review)", "(%{n} reviews)", count) % { n: count },
            service_opinions_path(service),
            class: "ml-1 default-color",
            "data-target": preview ? "preview.link" : ""
  end

  def my_providers_link
    "#{Mp::Application.config.providers_dashboard_url}/provider/my"
  end

  def show_manage_button?(record)
    policy(record).data_administrator? && record.upstream&.eosc_registry?
  end

  def about_link(service, query_params)
    query_params ||= {}
    from = query_params[:from]
    case from
    when "ordering_configuration"
      service_ordering_configuration_path(service, query_params)
    when "backoffice_service"
      backoffice_service_path(service, query_params)
    else
      service_path(service, query_params)
    end
  end

  def offers_link(service, query_params)
    query_params ||= {}
    from = query_params[:from]
    case from
    when "ordering_configuration"
      service_ordering_configuration_offers_path(service, query_params)
    when "backoffice_service"
      backoffice_service_offers_path(service, query_params)
    else
      service_offers_path(service, query_params)
    end
  end

  def datasource_about_link(datasource, from)
    case from
    when "backoffice_datasource"
      backoffice_datasource_path(datasource, { from: from })
    else
      datasource_path(datasource)
    end
  end

  def preview_link_parameters(is_preview)
    if is_preview
      { disabled: true, tabindex: -1, class: "disabled", "data-tooltip": "Element disabled in the preview mode" }
    else
      { "data-controller": "favourite" }
    end
  end

  def ess_providers_resources_link(provider)
    query = "/search/all_collection?q=*&fq=providers:\"#{provider.name}\"&fq=resource_organisation:\"#{provider.name}\""

    Rails.configuration.search_service_base_url + query
  end
end
