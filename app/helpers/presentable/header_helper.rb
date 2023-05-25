# frozen_string_literal: true

module Presentable::HeaderHelper
  def service_header_fields
    [links]
  end

  def provider_header_fields
    [provider_links, status]
  end

  def datasource_header_fields
    [datasource_links]
  end

  def service_opinions_link(service, preview)
    count = service.service_opinion_count
    link_to n_("%{n} review", "%{n} reviews", count) % { n: count },
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
      {}
    end
  end

  private

  def links
    {
      name: "links",
      template: "links",
      fields: %w[webpage_url helpdesk_url helpdesk_email manual_url training_information_url]
    }
  end

  def provider_links
    { name: "links", template: "links", fields: %w[website] }
  end

  def datasource_links
    {
      name: "links",
      template: "links",
      fields: %w[webpage_url helpdesk_url helpdesk_email manual_url training_information_url]
    }
  end

  def status
    {
      name: "statuses",
      template: "list",
      fields: %w[legal_statuses provider_life_cycle_statuses],
      nested: {
        legal_statuses: "name",
        provider_life_cycle_statuses: "name"
      }
    }
  end
end
