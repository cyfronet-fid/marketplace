# frozen_string_literal: true

class Backoffice::Services::DraftsController < Backoffice::ApplicationController
  before_action :find_and_authorize

  def create
    Service::Draft.call(@service)
    redirect_to [:backoffice, @service]
  end

  private

  def find_and_authorize
    @service = Service.friendly.find(params[:service_id])

    authorize(@service, :draft?)
  end
end
