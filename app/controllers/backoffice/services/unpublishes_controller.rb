# frozen_string_literal: true

class Backoffice::Services::UnpublishesController < Backoffice::ApplicationController
  before_action :find_and_authorize

  def create
    respond_to do |format|
      result = params[:suspend] ? Service::Suspend.call(@service) : Service::Unpublish.call(@service)
      if result
        type = :notice
        flash[type] = msg = "Service #{params[:suspend] ? "suspended" : "unpublished"} successfully"
      else
        type = :alert
        flash[type] = msg =
          "Service not #{params[:suspend] ? "suspended" : "unpublished"}. " +
          "Reason: #{@service.errors.full_messages.join(", ")}"
      end
      flash.now[type] = msg
      format.turbo_stream
      format.html { redirect_to backoffice_service_offers_path(@service) }
    end
  end

  private

  def find_and_authorize
    @service = Service.friendly.find(params[:service_id])

    authorize(@service, :unpublish?)
  end
end
