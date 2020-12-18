# frozen_string_literal: true

class Services::DataAdministratorsController < Services::ApplicationController
  # skip_before_action :authenticate_user!

  layout "application"

  def show
    @service = Service.includes(:offers).friendly.find(params[:service_id])
    @offers = policy_scope(@service.offers).order(:created_at)
  end
end
