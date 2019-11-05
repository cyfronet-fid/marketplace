# frozen_string_literal: true

class Services::ApplicationController < ApplicationController
  before_action :authenticate_user!
  before_action :load_and_authenticate_service!

  layout "order"

  protected

    def session_key
      @service.id.to_s
    end

    def ensure_in_session!
      unless session[session_key]
        redirect_to service_offers_path(@service),
                    alert: "Service request template not found"
      end
    end

  private

    def load_and_authenticate_service!
      @service = Service.friendly.find(params[:service_id])
      authorize(@service, :order?)
    end

    def save_in_session(step)
      session[session_key] = step.project_item.attributes
    end
end
