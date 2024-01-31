# frozen_string_literal: true

module Services::OrderingConfiguration::Bundles
  class DraftsController < Services::OrderingConfiguration::ApplicationController
    before_action :find_and_authorize

    def create
      if Bundle::Unpublish.call(@bundle)
        redirect_to service_ordering_configuration_path(@service)
      else
        flash[:alert] = "Bundle cannot be set to draft. Please ensure your form is properly completed. " +
          "#{@bundle.errors.messages.each.map { |k, v| "The field #{k} #{v.join(", ")}" }.join(", ")}"
        redirect_to edit_service_ordering_configuration_bundle_path(@service, @bundle)
      end
    end

    private

    def find_and_authorize
      @service = Service.friendly.find(params[:service_id])
      @bundle = @service.bundles.find_by(iid: params[:bundle_id])
      authorize(@bundle, :draft?)
    end
  end
end
