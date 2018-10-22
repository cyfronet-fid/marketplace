# frozen_string_literal: true

class Services::ConfigurationsController < Services::ApplicationController
  def show
  end

  def update
    # TODO store selected elements in user session
    redirect_to service_summary_path(@service)
  end
end
