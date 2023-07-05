# frozen_string_literal: true

class Backoffice::Services::Offers::PublishesController < Backoffice::ApplicationController
  before_action :find_and_authorize

  def create
    if Offer::Publish.call(@offer)
      redirect_to backoffice_service_path(@service)
    else
      flash[:alert] = "Offer not published, errors: #{@offer.errors.messages}"
      redirect_to edit_backoffice_service_offer_path(@service, @offer)
    end
  end

  private

  def find_and_authorize
    @service = Service.friendly.find(params[:service_id])
    @offer = @service.offers.find_by(iid: params[:offer_id])
    authorize(@offer, :publish?)
  end
end
