# frozen_string_literal: true

class Providers::LogosController < ApplicationController
  def show
    @provider = Provider.with_attached_logo.friendly.find(params[:provider_id])
    authorize(@provider)
    if @provider.logo.attached? && @provider.logo.variable?
      redirect_to @provider.logo.variant(resize_to_limit: [84, 84]), allow_other_host: false
    else
      redirect_to ImageHelper::DEFAULT_PROVIDER_LOGO_PATH
    end
  end
end
