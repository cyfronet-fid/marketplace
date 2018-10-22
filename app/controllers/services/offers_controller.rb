# frozen_string_literal: true

class Services::OffersController < Services::ApplicationController
  def index
    @offers = @service.offers
  end

  def update
    if offer
      session[@service.id.to_s] = { "offer_iid" => offer.iid }
      redirect_to service_configuration_path(@service)
    else
      @offers = @service.offers
      flash.now[:alert] = "Please select one of the offer"
      render :index
    end
  end

  private

    def offer
      @offer ||= @service.offers.find_by(iid: offer_params[:offer_id])
    end

    def offer_params
      params.require(:project_item).permit(:offer_id)
    end
end
