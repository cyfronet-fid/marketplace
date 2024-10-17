# frozen_string_literal: true

class Backoffice::Statuses::CataloguesController < Backoffice::ApplicationController
  include StatusChangeHelper

  def create
    @catalogues = Catalogue.where(id: params[:catalogue_ids])
    respond_to do |format|
      @catalogues.each do |catalogue|
        next if action_for(catalogue, params[:commit]).call(catalogue)
        alert =
          "Catalogue #{catalogue.name} was not #{params[:commit]}ed. " +
            "Reason: #{catalogue.errors.full_messages.to_sentence}"
        format.turbo_stream { flash.now[:alert] = alert and return nil }
        format.html { redirect_to backoffice_catalogues_path(page: params[:page]), alert: alert and return nil }
      end
      @catalogues.reload
      notice = "Selected Catalogues are successfully #{params[:commit]}ed."
      format.turbo_stream { flash.now[:notice] = notice }
      format.html { redirect_to backoffice_catalogues_path(page: params[:page]), notice: notice }
    end
  end
end
