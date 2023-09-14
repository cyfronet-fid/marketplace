# frozen_string_literal: true

class ProvidersController < ApplicationController
  def index
    @providers = policy_scope(Provider).order(:name)
  end

  def show
    @provider = Provider.with_attached_logo.friendly.find(params[:id])
    @provider.store_analytics
    authorize(@provider)

    @related_services = @provider.services.order(created_at: :desc).uniq.first(2)
    @question = Provider::Question.new(provider: @provider)
  end
end
