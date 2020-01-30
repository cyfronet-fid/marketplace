# frozen_string_literal: true

class Api::ServicesController < ActionController::API
  def index
    @json = Service.where(status: [:published, :unverified]).map { |s| { "serviceUniqueId": s.id,
                                                                         "serviceType": "eu.eosc.portal.services.url",
                                                                         "contactEmail": s.contact_emails,
                                                                         "sitenameServicegroup": s.title,
                                                                         "countryName": s.places,
                                                                         "url": s.webpage_url } }
    render json: @json
  end
end
