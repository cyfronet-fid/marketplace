# frozen_string_literal: true

class Backoffice::Services::PublishesController < Backoffice::ApplicationController
  before_action :find_and_authorize

  def create
    Service::Publish.call(@service)
    redirect_to backoffice_service_path(@service)
  end

  private

  def find_and_authorize
    @service = Service.friendly.find(params[:service_id])
    authorize(@service, :publish?)
  end
end
