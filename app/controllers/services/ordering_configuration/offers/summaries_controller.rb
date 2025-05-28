# frozen_string_literal: true

class Services::OrderingConfiguration::Offers::SummariesController < Backoffice::Services::OffersController
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
end
