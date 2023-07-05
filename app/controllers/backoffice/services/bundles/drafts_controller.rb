# frozen_string_literal: true

class Backoffice::Services::Bundles::DraftsController < Backoffice::ApplicationController
  before_action :find_and_authorize

  def create
    if Bundle::Draft.call(@bundle)
      redirect_to backoffice_service_path(@service)
    else
      flash[:alert] = "Bundle not drafted, errors: #{@bundle.errors.messages}"
      redirect_to edit_backoffice_service_offer_path(@service, @bundle)
    end
  end

  private

  def find_and_authorize
    @service = Service.friendly.find(params[:service_id])
    @bundle = @service.bundles.find_by(iid: params[:bundle_id])
    authorize(@bundle, :draft?)
  end
end
