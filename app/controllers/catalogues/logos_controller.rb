# frozen_string_literal: true

class Catalogues::LogosController < ApplicationController
  def show
    @catalogue = Catalogue.with_attached_logo.friendly.find(params[:catalogue_id])
    authorize(@catalogue)
    if @catalogue.logo.attached? && @catalogue.logo.variable?
      redirect_to @catalogue.logo.variant(resize: "84x84"), allow_other_host: false
    else
      redirect_to ImageHelper::DEFAULT_LOGO_PATH
    end
  end
end
