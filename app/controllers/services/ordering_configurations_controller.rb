# frozen_string_literal: true

class Services::OrderingConfigurationsController < Services::OrderingConfiguration::ApplicationController
  include Service::Monitorable

  before_action :load_and_authenticate_service!, only: :show

  layout "ordering_configuration"

  def show
    @offers = policy_scope(@service.offers)
    @bundles = policy_scope(@service.bundles)
    @related_services = @service.related_services
    @service.monitoring_status = fetch_status(@service.pid)
    @question = Service::Question.new(service: @service)
  end

  private

  def load_and_authenticate_service!
    @service = Service.friendly.find(params[:service_id])
    authorize(ServiceContext.new(@service, params.key?(:from) && params[:from] == "backoffice_service"), :show?)
  rescue Pundit::NotAuthorizedError => e
    flash[:alert] = if @service.suspended?
      "Configuration's panel is not available for the suspended #{@service.type}"
    else
      not_authorized_message(e)
    end
    redirect_to service_offers_path(@service)
  end
end
