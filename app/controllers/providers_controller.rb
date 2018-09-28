# frozen_string_literal: true

class ProvidersController < ApplicationController
  include Service::Searchable

  before_action :provider

  def show
    @services = Service.where(provider_id: params[:id]).page(params[:page])
  end

  private

    def provider
      @provider ||= Provider.find(params[:id])
    end
end
