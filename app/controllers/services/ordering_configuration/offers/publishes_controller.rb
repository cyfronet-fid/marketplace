# frozen_string_literal: true

module Services::OrderingConfiguration::Offers
  class PublishesController < Services::OrderingConfiguration::ApplicationController
    before_action :find_and_authorize

    def create
      Offer::Publish.call(@offer)
      redirect_to service_ordering_configuration_path(@service)
    end

    private

    def find_and_authorize
      @service = Service.friendly.find(params[:service_id])
      @offer = @service.offers.find_by(iid: params[:offer_id])
      authorize(@offer, :publish?)
    end
  end
end
