# frozen_string_literal: true

module Services::OrderingConfiguration::Bundles
  class PublishesController < Services::OrderingConfiguration::ApplicationController
    before_action :find_and_authorize

    def create
      if Bundle::Publish.call(@bundle)
        redirect_to backoffice_service_path(@service)
      else
        flash[:alert] =
          "Bundle not published, errors: " +
            "#{@bundle.errors.messages.each.map { |k, v| "The field #{k} #{v.join(", ")}" }.join(", ")}"
        redirect_to edit_backoffice_service_bundle_path(@service, @bundle)
      end
    end

    private

    def find_and_authorize
      @service = Service.friendly.find(params[:service_id])
      @bundle = @service.bundles.find_by(iid: params[:bundle_id])
      authorize(@bundle, :publish?)
    end
  end
end
