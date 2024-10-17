# frozen_string_literal: true

class Backoffice::Statuses::ProvidersController < Backoffice::ApplicationController
  include StatusChangeHelper
  def create
    @providers = Provider.where(id: params[:provider_ids])
    respond_to do |format|
      @providers.each do |provider|
        next if action_for(provider, params[:commit]).call(provider)
        alert =
          "Provider #{provider.name} was not #{params[:commit]}ed. " +
            "Reason: #{provider.errors.full_messages.to_sentence}"
        format.turbo_stream { flash.now[:alert] = alert }
        format.html { redirect_to backoffice_statuses_providers_path, alert: alert and return nil }
      end
      @providers.reload
      notice = "Selected Providers are successfully #{params[:commit]}ed."
      format.turbo_stream { flash.now[:notice] = notice }
      format.html { redirect_to backoffice_providers_path, notice: notice }
    end
  end
end
