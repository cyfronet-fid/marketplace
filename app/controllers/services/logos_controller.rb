# frozen_string_literal: true

class Services::LogosController < ApplicationController
  def show
    @service = Service.friendly.find(params[:service_id])
    authorize(ServiceContext.new(@service, false))
    redirect_to @service.logo.variant(resize: "84x84"), allow_other_host: false
  end
end
