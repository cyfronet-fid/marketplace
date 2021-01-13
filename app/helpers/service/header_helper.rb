# frozen_string_literal: true

module Service::HeaderHelper
  def service_header_fields
    [links]
  end

  def resource_link(service)
    if service.pid.present?
      "https://providers.eosc-portal.eu/resource-dashboard/#{service.pid.split(".").first}/#{service.pid}/stats"
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
end
