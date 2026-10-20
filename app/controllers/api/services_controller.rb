# frozen_string_literal: true

class Api::ServicesController < ActionController::API
  def index
    @json =
      published_services.map do |s|
        {
          "Service Unique ID": s.id,
          SERVICE_TYPE: "eu.eosc.portal.services.url",
          CONTACT_EMAIL: contact_email(s),
          "SITENAME-SERVICEGROUP": s.name,
          COUNTRY_NAME: country_name(s),
          URL: s.webpage_url
        }
      end
    render json: @json
  end

  private

  # Only `pl` kept `geographical_availabilities` and the `public_contacts`
  # association through the V6 migration (StripServiceToV6). `whitelabel`
  # stubbed both via Service::V6_REMOVED_ARRAY_FIELDS, so its own
  # `includes(:public_contacts)` raised; it shares marketplace's data shape.
  def published_services
    scope = Service.where(status: :published)
    Mp::Variant.pl? ? scope.includes(:public_contacts) : scope
  end

  def contact_email(service)
    Mp::Variant.pl? ? service.public_contacts.map(&:email) : service.public_contact_emails
  end

  def country_name(service)
    Mp::Variant.pl? ? service.geographical_availabilities : []
  end
end
