# frozen_string_literal: true

class Backoffice::Services::DraftsController < Backoffice::ApplicationController
  before_action :find_and_authorize

  def create
    result = params[:suspend] ? Service::Suspend.call(@service) : Service::Unpublish.call(@service)
    if result
      flash[:notice] = "Service #{params[:suspend] ? "suspended" : "unpublished"} successfully"
    else
      flash[:alert] = "Service not #{params[:suspend] ? "suspended" : "unpublished"}. " +
        "Reason: #{@service.errors.full_messages.join(", ")}"
    end
    redirect_to backoffice_service_offers_path(@service)
  end

  private

  def find_and_authorize
    @service = Service.friendly.find(params[:service_id])

    authorize(@service, :unpublish?)
  end
end
