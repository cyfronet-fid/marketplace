# frozen_string_literal: true

class Services::DetailsController < ApplicationController
  include Service::Comparison

  def index
    @service = Service.friendly.find(params[:service_id])
    @related_services = @service.related_services
    @question = Service::Question.new(service: @service)
  end
end
