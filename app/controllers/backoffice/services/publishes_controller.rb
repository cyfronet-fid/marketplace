# frozen_string_literal: true

class Backoffice::Services::PublishesController < Backoffice::ApplicationController
  before_action :find_and_authorize

  def create
    if Service::Publish.call(@service)
      flash[:notice] = _("Service published successfully")
    else
      flash[:alert] = "Service not published. Reason: #{@service.errors.full_messages.join(", ")}"
    end
    redirect_to backoffice_service_offers_path(@service)
  end

  private

  def find_and_authorize
    @service = Service.friendly.find(params[:service_id])
    authorize(@service, :publish?)
  end
end
