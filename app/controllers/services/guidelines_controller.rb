# frozen_string_literal: true

class Services::GuidelinesController < ApplicationController
  include Service::Comparison
  include Service::Recommendable
  layout :choose_layout

  def index
    @service = Service.friendly.find(params[:service_id])
    authorize(ServiceContext.new(@service, params.key?(:from) && params[:from] == "backoffice_service"), :show?)
    @similar_services = fetch_similar(@service.id, current_user&.id)
    @related_services = @service.related_services
    @question = Service::Question.new(service: @service)
    @favourite_services =
      current_user&.favourite_services || Service.where(slug: Array(cookies[:favourites]&.split("&") || []))
  end
end
