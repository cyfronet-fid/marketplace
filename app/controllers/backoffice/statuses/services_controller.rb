# frozen_string_literal: true

class Backoffice::Statuses::ServicesController < Backoffice::ApplicationController
  include StatusChangeHelper
  def create
    @services = Service.where(id: params[:service_ids])
    respond_to do |format|
      @services.each do |service|
        next if action_for(service, params[:commit]).call(service)
        alert =
          "Service #{service.name} was not #{params[:commit]}ed. " +
            "Reason: #{service.errors.full_messages.to_sentence}"
        format.turbo_stream { flash.now[:alert] = alert }
        format.html { redirect_to backoffice_statuses_services_path, alert: alert and return nil }
      end
      @services.reload
      notice = "Selected Services are successfully #{params[:commit]}ed."
      format.turbo_stream { flash.now[:notice] = notice }
      format.html { redirect_to backoffice_services_path, notice: notice }
    end
  end
end
