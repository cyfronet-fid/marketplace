# frozen_string_literal: true

class Backoffice::Services::OffersController < Backoffice::ApplicationController
  before_action :find_service
  before_action :find_offer_and_authorize, only: [:destroy, :edit, :update]

  def new
    @offer = Offer.new(service: @service)
    authorize(@offer)
  end

  def create
    template = offer_template
    authorize(template)

    @offer = Offer::Create.new(template).call

    if @offer.persisted?
      redirect_to backoffice_service_path(@service),
                  notice: "New offer has been created"
    else
      render :new, status: :bad_request
    end
  end

  def edit
  end

  def update
    if Offer::Update.new(@offer, permitted_attributes(@offer)).call
      redirect_to backoffice_service_path(@service, @offer),
                  notice: "Offer updated correctly"
    else
      render :edit, status: :bad_request
    end
  end

  def destroy
    Offer::Destroy.new(@offer).call
    redirect_to backoffice_service_path(@service),
                notice: "Offer destroyed"
  end

  private
    def offer_template
      Offer.new(permitted_attributes(Offer).
                                  merge(service: @service))
    end

    def find_service
      @service = Service.friendly.find(params[:service_id])
    end

    def find_offer_and_authorize
      @offer = @service.offers.find_by(iid: params[:id])
      authorize(@offer)
    end
end
