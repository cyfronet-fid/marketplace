# frozen_string_literal: true

class Api::ServicesController < ActionController::API
  def index
    @json =
      Service
        .where(status: :published)
        .map do |s|
          {
            "Service Unique ID": s.id,
            SERVICE_TYPE: "eu.eosc.portal.services.url",
            CONTACT_EMAIL: s.public_contact_emails,
            "SITENAME-SERVICEGROUP": s.name,
            COUNTRY_NAME: [],
            URL: s.webpage_url
          }
        end
    render json: @json
  end
end
