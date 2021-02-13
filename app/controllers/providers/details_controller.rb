# frozen_string_literal: true

class Providers::DetailsController < ApplicationController
  def index
    # @service = Service.friendly.find(params[:service_id])
    # @related_services = @service.related_services
    @provider = Provider.with_attached_logo.friendly.find(params[:provider_id])
  end
end
