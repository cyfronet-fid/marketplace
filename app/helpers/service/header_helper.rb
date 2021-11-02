# frozen_string_literal: true

module Service::HeaderHelper
  def service_header_fields
    [links]
  end

  def provider_header_fields
    [provider_links, status]
  end

  def resource_link(service)
    if service.pid.present?
      "#{Mp::Application.config
                        .providers_dashboard_url}/resource-dashboard/#{service.pid
                                                                              .split(".")
                                                                              .first}/#{service.pid}/stats"
    else
      service_path(service)
    end
  end

  def my_providers_link
    "#{Mp::Application.config.providers_dashboard_url}/provider/my"
  end

  def about_link(service, from)
    if from == "ordering_configuration"
      service_ordering_configuration_path(service, { from: from })
    elsif from == "backoffice_service"
      backoffice_service_path(service, { from: from })
    else
      service_path(service)
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
      {
        name: "links",
        template: "links",
        fields: %w[website]
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
