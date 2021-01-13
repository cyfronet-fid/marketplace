# frozen_string_literal: true

class Services::OrderingConfigurationsController < Services::ApplicationController
  before_action :authenticate_user!
  before_action :data_administrator_authorization!, only: :show

  layout "application"

  def show
    @service = Service.includes(:offers).friendly.find(params[:service_id])
    @offers = @service.offers.order(:iid)
    if current_user&.executive?
      @client = @client&.credentials&.expires_at.blank? ? Google::Analytics.new : @client
      @analytics = Analytics::PageViewsAndRedirects.new(@client).call(request.path)
    end
  end

  private
    def data_administrator_authorization!
      authorize @service, policy_class: OrderingConfigurationPolicy
    end
end
