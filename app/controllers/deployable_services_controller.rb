# frozen_string_literal: true

class DeployableServicesController < ApplicationController
  def index
    @deployable_services = policy_scope(DeployableService).order(:name)
  end

  def show
    @deployable_service = DeployableService.with_attached_logo.friendly.find(params[:id])
    authorize(@deployable_service)
  end
end
