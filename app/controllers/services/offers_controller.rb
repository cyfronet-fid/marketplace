# frozen_string_literal: true

class Services::OffersController < Services::ApplicationController
  def index
    @offers = @service.offers
  end

  def update
    # TODO store selected offer in session
    redirect_to service_configuration_path(@service)
  end
end
