# frozen_string_literal: true

class Backoffice::Services::PublishesController < Backoffice::ApplicationController
  before_action :find_and_authorize

  def create
    Service::Publish.new(@service, verified: verified?).call
    redirect_to [:backoffice, @service]
  end

  private

    def find_and_authorize
      @service = Service.friendly.find(params[:service_id])

      authorize(@service, verified? ? :publish? : :publish_unverified?)
    end

    def verified?
      params[:unverified] != "true"
    end
end
