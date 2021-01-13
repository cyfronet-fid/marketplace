# frozen_string_literal: true

class Backoffice::Services::OffersController < Backoffice::ApplicationController
  before_action :find_service
  before_action :find_offer_and_authorize, only: [:destroy, :edit, :update]
  after_action :reindex_offer, only: [:create, :update, :destroy]

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
    template = permitted_attributes(Offer.new)
    if Offer::Update.new(@offer, update_blank_parameters(template)).call
      redirect_to backoffice_service_path(@service),
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
    def reindex_offer
      if @service.offers.size > 1
        @service.offers.reindex
      end
    end

    def offer_template
      temp = update_blank_parameters(permitted_attributes(Offer))
      Offer.new(temp.merge(service: @service, status: :published))
    end

    def update_blank_parameters(template)
      if template["parameters_attributes"].blank?
        template["parameters_attributes"] = []
      end
      template
    end

    def find_service
      @service = Service.friendly.find(params[:service_id])
    end

    def find_offer_and_authorize
      @offer = @service.offers.find_by(iid: params[:id])
      authorize(@offer)
    end
end
