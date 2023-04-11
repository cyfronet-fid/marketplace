# frozen_string_literal: true

class Backoffice::Services::OffersController < Backoffice::ApplicationController
  before_action :find_service
  before_action :find_offer_and_authorize, only: %i[edit update]
  after_action :reindex_offer, only: %i[create update destroy]

  def new
    @offer = Offer.new(service: @service)
    authorize(@offer)
  end

  def create
    template = offer_template
    authorize(template)

    @offer = Offer::Create.call(template)

    if @offer.persisted?
      redirect_to backoffice_service_path(@service), notice: "New offer created successfully"
    else
      render :new, status: :bad_request
    end
  end

  def edit; end

  def update
    template = permitted_attributes(Offer.new)
    if Offer::Update.call(@offer, transform_attributes(template, @service))
      redirect_to backoffice_service_path(@service), notice: "Offer updated successfully"
    else
      render :edit, status: :bad_request
    end
  end

  def destroy
    @offer = @service.offers.find_by(iid: params[:id])
    if @offer.main_bundles.size.positive?
      redirect_back fallback_location: edit_backoffice_service_offer_path(@offer),
                    alert:
                      "This offer is connected as main offer to the bundle,
                       therefore is not possible to remove it. If you want to remove it,
                       edit bundle and choose another main offer."
    elsif @offer.bundles.size.positive?
      redirect_back fallback_location: edit_backoffice_service_offer_path(@offer),
                    alert:
                      "This offer is connected to the bundle,
                       therefore is not possible to remove it. If you want to remove it,
                       edit bundles #{@offer.bundles.map(&:name).split(", ")} and choose another main offer."
    elsif Offer::Destroy.call(@offer)
      redirect_to backoffice_service_path(@service), notice: "Offer removed successfully"
    end
  end

  private

  def reindex_offer
    @service.offers.reindex if @service.offers.size > 1
  end

  def offer_template
    temp = transform_attributes(permitted_attributes(Offer), @service)
    Offer.new(temp.merge(service: @service, status: :published))
  end

  def transform_attributes(template, service)
    template["service_id"] = service.id

    template["parameters_attributes"] = [] if template["parameters_attributes"].blank?
    template["oms_params"] = {} if template["primary_oms_id"].present? && template["oms_params"].nil?
    template.except(:from)
  end

  def find_service
    @service = Service.friendly.find(params[:service_id])
  end

  def find_offer_and_authorize
    @offer = @service.offers.find_by(iid: params[:id])
    authorize(@offer)
  end
end
