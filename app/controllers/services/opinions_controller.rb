# frozen_string_literal: true

class Services::OpinionsController < ApplicationController
  def index
    @service = Service.find(params[:service_id])
    @service_opinions = ServiceOpinion.joins(project_item: :offer).
        where(offers: { service_id: @service })
    @question = Service::Question.new(service: @service)
  end
end
