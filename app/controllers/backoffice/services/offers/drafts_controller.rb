# frozen_string_literal: true

class Backoffice::Services::Offers::DraftsController < Backoffice::ApplicationController
  before_action :find_and_authorize

  def create
    if Offer::Draft.call(@offer)
      flash[:notice] = "Offer changed to draft successfully"
      redirect_to backoffice_service_path(@service)
    else
      flash[:alert] = "Offer cannot be changed to draft"
      redirect_to edit_backoffice_service_offer_path(@service, @offer)
    end
  end

  private

  def find_and_authorize
    @service = Service.friendly.find(params[:service_id])
    @offer = @service.offers.find_by(iid: params[:offer_id])
    authorize(@offer, :draft?)
  end
end
