# frozen_string_literal: true

class Api::ServicesController < ActionController::API
  def index
    @json = Service.where(status: [:published, :unverified]).map {
            |s| { "Service Unique ID": s.id,
            "SERVICE_TYPE": "eu.eosc.portal.services.url",
            "CONTACT_EMAIL": s.public_contacts.map(&:email),
            "SITENAME-SERVICEGROUP": s.name,
            "COUNTRY_NAME": s.geographical_availabilities,
            "URL": s.webpage_url } }
    render json: @json
  end
end
