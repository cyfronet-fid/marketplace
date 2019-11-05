# frozen_string_literal: true

class Services::InformationController < Services::ApplicationController
  before_action :ensure_in_session!

  def show
    @offer = Offer.find(session[session_key]["offer_id"])
  end
end
