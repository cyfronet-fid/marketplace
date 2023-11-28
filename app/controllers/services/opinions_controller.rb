# frozen_string_literal: true

class Services::OpinionsController < ApplicationController
  include Service::Comparison
  include Service::Recommendable
  layout :choose_layout

  def choose_layout
    case params[:from]
    when "backoffice_service"
      "backoffice"
    when "ordering_configuration"
      "ordering_configuration"
    else
      "application"
    end
  end

  def index
    @service = Service.friendly.find(params[:service_id])
    authorize(ServiceContext.new(@service, params.key?(:from) && params[:from] == "backoffice_service"), :show?)
    @similar_services = fetch_similar(@service.id, current_user&.id)
    @related_services = @service.related_services
    @service_opinions =
      ServiceOpinion
        .includes(project_item: :offer)
        .where(offers: { service_id: @service })
        .includes(project_item: :project)
    @question = Service::Question.new(service: @service)
    @favourite_services =
      current_user&.favourite_services || Service.where(slug: Array(cookies[:favourites]&.split("&") || []))
  end
end
