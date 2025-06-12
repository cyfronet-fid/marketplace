# frozen_string_literal: true

class Backoffice::Services::Offers::SummariesController < Backoffice::Services::OffersController
  before_action :find_service
  before_action :find_offer_and_authorize, only: %i[update]

  def create
    submit_summary
  end

  def update
    submit_summary
  end

  def submit_summary
    template = offer_template
    authorize(template)
    render partial: "backoffice/services/offers/steps/summary", locals: { offer: template }
  end

  private

  def find_offer_and_authorize
    @offer = @service.offers.find_by(iid: params[:offer_id])
    authorize(@offer)
  end
end
