# frozen_string_literal: true

class Services::CancelsController < Services::ApplicationController
  skip_before_action :authenticate_user!

  def destroy
    session.delete(session_key)
    session.delete(:selected_project)

    redirect_to service_offers_path(@service)
  end
end
