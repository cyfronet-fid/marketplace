# frozen_string_literal: true

class Services::DetailsController < ApplicationController
  include Service::Comparison
  layout :choose_layout

  def choose_layout
    if params[:from] == "backoffice_service"
      "backoffice"
    elsif params[:from] == "ordering_configuration"
      "ordering_configuration"
    else
      "application"
    end
  end

  def index
    @service = Service.friendly.find(params[:service_id])
    authorize(ServiceContext.new(@service, params.key?(:from) && params[:from] == "backoffice_service"), :show?)
    @related_services = @service.related_services
    @related_services_title = "Related resources"
    @question = Service::Question.new(service: @service)
  end
end
