# frozen_string_literal: true

class Services::OrderingConfigurationsController < Services::OrderingConfiguration::ApplicationController
  include Service::Monitorable

  before_action :load_and_authenticate_service!, only: :show

  layout "ordering_configuration"

  def show
    @service = Service.includes(:offers).friendly.find(params[:service_id])
    @offers = @service&.offers&.published&.order(:iid)
    @bundles = @service.bundles.published
    @related_services = @service.related_services
    @client = @client&.credentials&.expires_at.blank? ? Google::Analytics.new : @client
    @service.analytics = Analytics::PageViewsAndRedirects.new(@client).call(request.path)
    @service.monitoring_status = fetch_status(@service.pid)
  end

  private

  def load_and_authenticate_service!
    @service = Service.friendly.find(params[:service_id])
    authorize(ServiceContext.new(@service, params.key?(:from) && params[:from] == "backoffice_service"), :show?)
  end
end
