# frozen_string_literal: true

class Services::OrderingConfiguration::OffersController < Services::OrderingConfiguration::ApplicationController
  before_action :find_service
  before_action :find_offer_and_authorize, only: %i[edit update]
  after_action :reindex_and_set_default_offer, only: %i[create update destroy]

  def new
    @offer = Offer.new(service: @service)
    authorize(ServiceContext.new(@service, params.key?(:from) && params[:from] == "backoffice_service"), :show?)
    authorize @offer
  end

  def edit
  end

  def create
    template = offer_template
    authorize template

    @offer = Offer::Create.call(template)

    if @offer.persisted?
      redirect_to service_ordering_configuration_path(@service, from: params[:offer][:from]),
                  notice: "New offer created successfully"
    else
      render :new, status: :bad_request, locals: { from: params[:offer][:from] }
    end
  end

  def update
    template = permitted_attributes(Offer.new)
    if Offer::Update.call(@offer, transform_attributes(template))
      redirect_to service_ordering_configuration_path(@service, from: params[:offer][:from]),
                  notice: "Offer updated successfully"
    else
      render :edit, status: :bad_request, locals: { from: params[:offer][:from] }
    end
  end

  def destroy
    @offer = @service.offers.find_by(iid: params[:id])
    if Offer::Delete.call(@offer)
      redirect_to service_ordering_configuration_path(@service, from: params[:from]),
                  notice: "Offer removed successfully"
    end
  end

  private

  def reindex_and_set_default_offer
    if @service.offers_count > 1
      @service.offers.reindex
    elsif @service.offers_count == 1
      @service.offers.first.update!(default: true)
    end
  end

  def offer_template
    temp = transform_attributes(permitted_attributes(Offer))
    Offer.new(temp.merge(service: @service, default: false, status: :published))
  end

  def transform_attributes(template)
    template["parameters_attributes"] = [] if template["parameters_attributes"].blank?
    template["oms_params"] = {} if template["primary_oms_id"].present? && template["oms_params"].nil?
    template.except(:from)
  end

  def find_service
    @service = Service.friendly.find(params[:service_id])
  end

  def find_offer_and_authorize
    @offer = @service.offers.find_by(iid: params[:id])
    authorize @offer
  end
end
