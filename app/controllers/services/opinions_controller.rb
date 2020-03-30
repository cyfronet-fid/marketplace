# frozen_string_literal: true

class Services::OpinionsController < ApplicationController
  include Service::Comparison

  def index
    @service = Service.friendly.find(params[:service_id])
    @related_services = @service.related_services
    @service_opinions = ServiceOpinion.includes(project_item: :offer).
        where(offers: { service_id: @service }).includes(project_item: :project)
    @question = Service::Question.new(service: @service)
  end
end
