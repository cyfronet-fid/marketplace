# frozen_string_literal: true

class Services::CancelsController < Services::ApplicationController
  def destroy
    # TODO clear order data stored in session
    redirect_to service_path(@service)
  end
end
