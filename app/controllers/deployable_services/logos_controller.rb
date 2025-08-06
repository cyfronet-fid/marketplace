# frozen_string_literal: true

class DeployableServices::LogosController < ApplicationController
  include ActionView::Helpers::AssetUrlHelper

  def show
    @deployable_service = DeployableService.with_attached_logo.friendly.find(params[:deployable_service_id])
    authorize(@deployable_service)

    if @deployable_service.logo.attached? && @deployable_service.logo.variable?
      redirect_to @deployable_service.logo.variant(resize_to_limit: [84, 84]), allow_other_host: false
    else
      redirect_to ActionController::Base.helpers.asset_url(ImageHelper::DEFAULT_LOGO_PATH, type: :image)
    end
  end
end
