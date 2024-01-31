# frozen_string_literal: true

class Backoffice::Services::DraftsController < Backoffice::ApplicationController
  before_action :find_and_authorize

  def create
    result = params[:suspend] ? Service::Suspend.call(@service) : Service::Unpublish.call(@service)
    if result
      flash[:notice] = "Service #{params[:suspend] ? "suspended" : "unpublished"} successfully"
      redirect_to backoffice_service_path(@service)
    else
      flash[:alert] = "Service not #{params[:suspend] ? "suspended" : "unpublished"}. " +
        "Reason: #{@service.errors.full_messages.join(", ")}"
      redirect_to edit_backoffice_service_path(@service)
    end
  end

  private

  def find_and_authorize
    @service = Service.friendly.find(params[:service_id])

    authorize(@service, :draft?)
  end
end
