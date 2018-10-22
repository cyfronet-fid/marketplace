# frozen_string_literal: true

class Services::ConfigurationsController < Services::ApplicationController
  before_action :find_offer

  def show
  end

  def update
    # TODO store selected elements in user session
    redirect_to service_summary_path(@service)
  end

  private

    def find_offer
      @offer ||= @service.offers.find_by(iid: offer_iid)
    end

    def offer_iid
      session[@service.id.to_s]["offer_iid"]
    end
end
