# frozen_string_literal: true

class Backoffice::Services::Bundles::PublishesController < Backoffice::ApplicationController
  before_action :find_and_authorize

  def create
    if Bundle::Publish.call(@bundle)
      flash[:notice] = "Bundle published successfully"
      redirect_to backoffice_service_offers_path(@service)
    else
      flash[:alert] = "Bundle cannot be published. Please ensure your form is properly completed. " +
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
