# frozen_string_literal: true

class Services::Offers::NotificationsController < ServicesController
  before_action :find

  def create
    @notification_request = ObservedUserOffer.create(offer_id: @offer.id, user_id: current_user.id)
    if @notification_request.present?
      flash.now[:notice] = "You will be notified when the product is available again."
      @offer.reload
    else
      flash.now[:alert] = "Failed to set the notification. Please try again or contact support for assistance."
    end
  end

  def destroy
    @notification_request = ObservedUserOffer.find(params[:id])
    if @notification_request.destroy
      flash.now[:notice] = "You will no longer receive notifications about this product's availability."
    else
      flash.now[:alert] = "Failed to disable the notification. Please try again or contact support for assistance."
    end
  end

  def find
    @service = Service.includes(:offers).friendly.find(params[:service_id])
    @offer = @service.offers.find_by(iid: params[:offer_id])
  end
end
