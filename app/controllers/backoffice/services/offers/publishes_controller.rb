# frozen_string_literal: true

class Backoffice::Services::Offers::PublishesController < Backoffice::ServicesController
  before_action :find_and_authorize

  def create
    Offer::Publish.new(@offer).call
    redirect_to [:backoffice, @service]
  end

  private

    def find_and_authorize
      @service = Service.friendly.find(params[:service_id])
      @offer = @service.offers.find_by(iid: params["offer_id"])

      authorize(@offer, :publish?)
    end
end
