# frozen_string_literal: true

class Catalogues::LogosController < ApplicationController
  def show
    @catalogue = Catalogue.with_attached_logo.friendly.find(params[:catalogue_id])
    authorize(@catalogue)
    if @catalogue.logo.attached? && @catalogue.logo.variable?
      redirect_to @catalogue.logo.variant(resize_to_limit: [84, 84]), allow_other_host: false
    else
      redirect_to ActionController::Base.helpers.asset_url(ImageHelper::DEFAULT_CATALOGUE_LOGO_PATH, type: :image)
    end
  end
end
