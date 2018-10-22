# frozen_string_literal: true

class Services::ApplicationController < ApplicationController
  before_action :authenticate_user!
  before_action :load_and_authenticate_service!

  layout "order"

  private

    def load_and_authenticate_service!
      @service = Service.find(params[:service_id])
      authorize(@service, :show?)
    end
end
