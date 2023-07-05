# frozen_string_literal: true

class Services::OrderingConfiguration::Offers::DraftsController < Services::OrderingConfiguration::ApplicationController
  before_action :find_and_authorize

  def create
    Offer::Draft.call(@offer)
    redirect_to backoffice_service_path(@service)
  end

  private

  def find_and_authorize
    @service = Service.friendly.find(params[:service_id])
    @offer = @service.offers.find_by(iid: params[:offer_id])
    authorize(@offer, :draft?)
  end
end
