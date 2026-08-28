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

  # The `marketplace` variant never populated `geographical_availabilities` or
  # the `public_contacts` association - see ADR-0001's controller audit and
  # StripServiceToV6. Only pl/whitelabel serve real data for either field.
  def published_services
    scope = Service.where(status: :published)
    Mp::Variant.marketplace? ? scope : scope.includes(:public_contacts)
  end

  def contact_email(service)
    Mp::Variant.marketplace? ? service.public_contact_emails : service.public_contacts.map(&:email)
  end

  def country_name(service)
    Mp::Variant.marketplace? ? [] : service.geographical_availabilities
  end
end
