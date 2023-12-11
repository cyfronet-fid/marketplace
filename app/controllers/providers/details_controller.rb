# frozen_string_literal: true

class Providers::DetailsController < ApplicationController
  def index
    @provider = Provider.with_attached_logo.friendly.find(params[:provider_id])
    @question = Provider::Question.new(provider: @provider)
    authorize(@provider, :show?)
  end
end
