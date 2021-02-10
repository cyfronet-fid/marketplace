# frozen_string_literal: true

class ProvidersController < ApplicationController
  def index
    @providers = Provider.all.order(:name)
  end

  def show
    @provider = Provider.friendly.find(params[:id])
    @related_services = @provider.services.order(created_at: :desc).limit(2)
    @question = Provider::Question.new(provider: @provider)
  end
end
