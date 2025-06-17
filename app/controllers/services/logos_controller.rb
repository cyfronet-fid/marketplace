# frozen_string_literal: true

class Services::LogosController < ApplicationController
  include ActionView::Helpers::AssetUrlHelper

  def show
    @service = Service.friendly.find(params[:service_id])
    authorize(ServiceContext.new(@service, params.key?(:from) && params[:from] == "backoffice_service"))

    if @service.logo.attached? && @service.logo.variable?
      redirect_to @service.logo.variant(resize_to_limit: [84, 84]), allow_other_host: false
    else
      redirect_to ActionController::Base.helpers.asset_url(ImageHelper::DEFAULT_LOGO_PATH)
    end
  end
end
