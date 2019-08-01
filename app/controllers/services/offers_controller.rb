# frozen_string_literal: true

class Services::OffersController < Services::ApplicationController
  def index
    init_offer_selection!

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
      init_offer_selection!
      flash.now[:alert] = "Please select one of the offer"
      render :index
    end
  end

  private

    def select_offer(offer)
      session[session_key] ||= {}
      session[session_key]["offer_id"] = offer.id
      session[session_key]["project_id"] ||= session[:selected_project]
    end

    def offer
      @offer ||= @service.offers.find_by(iid: offer_params[:offer_id])
    end

    def offer_params
      params.fetch(:project_item, {}).permit(:offer_id)
    end

    def init_offer_selection!
      @offers = @service.offers.reject { |o| o.catalog? || o.draft? }
      @project_item = ProjectItem.new(session[session_key])
    end
end
