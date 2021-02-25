# frozen_string_literal: true

class Services::OpinionsController < ApplicationController
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
    @related_services = @service.related_services
    @related_services_title = "Related resources"
    @service_opinions = ServiceOpinion.includes(project_item: :offer).
        where(offers: { service_id: @service }).includes(project_item: :project)
    @question = Service::Question.new(service: @service)
  end
end
