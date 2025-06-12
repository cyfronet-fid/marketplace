# frozen_string_literal: true

class Backoffice::Services::Offers::PublishesController < Backoffice::ApplicationController
  before_action :find_and_authorize

  def create
    if Offer::Publish.call(@offer)
      flash[:notice] = "Offer published successfully"
      redirect_to backoffice_service_offers_path(@service)
    else
      flash[:alert] = "Offer cannot be published. Please ensure your form is properly completed. " +
        "#{@offer.errors.messages.each.map { |k, v| "The field #{k} #{v.join(", ")}" }.join(", ")}"
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
