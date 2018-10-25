# frozen_string_literal: true

class Services::OffersController < Services::ApplicationController
  def index
    @offers = @service.offers

    if @service.offers_count == 1
      select_offer(@offers.first)
      redirect_to service_configuration_path(@service)
    end
  end

  def update
    if offer
      select_offer(offer)
      redirect_to service_configuration_path(@service)
    else
      @offers = @service.offers
      flash.now[:alert] = "Please select one of the offer"
      render :index
    end
  end

  private

    def select_offer(offer)
      session[session_key] = { "offer_id" => offer.id }
    end

    def offer
      @offer ||= @service.offers.find_by(iid: offer_params[:offer_id])
    end

    def offer_params
      params.require(:project_item).permit(:offer_id)
    end
end
