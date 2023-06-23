# frozen_string_literal: true

class Providers::LogosController < ApplicationController
  def show
    @provider = Provider.with_attached_logo.friendly.find(params[:provider_id])
    authorize(@provider)
    redirect_to @provider.logo.variant(resize: "84x84"), allow_other_host: false
  end
end
