# frozen_string_literal: true

module Service::HeaderHelper
  def service_header_fields
    [links]
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
