# frozen_string_literal: true

class Services::CancelsController < Services::ApplicationController
  def destroy
    session.delete(session_key)
    session.delete(:selected_project)

    redirect_to service_path(@service)
  end
end
