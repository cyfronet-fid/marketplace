# frozen_string_literal: true

class Backoffice::Services::BundlesController < Backoffice::ApplicationController
  before_action :find_service
  before_action :find_bundle_and_authorize, only: %i[edit update]
  after_action :reindex_offer, only: %i[create update destroy]

  def new
    @bundle = Bundle.new(service: @service)
    authorize(@bundle)
  end

  def create
    template = bundle_template
    authorize(template)

    @bundle = Bundle::Create.call(template)

    if @bundle.persisted?
      redirect_to backoffice_service_offers_path(@service), notice: "New bundle created successfully"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    template = permitted_attributes(Bundle.new)
    if Bundle::Update.call(@bundle, transform_attributes(template))
      redirect_to backoffice_service_offers_path(@service), notice: "Bundle updated successfully"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @bundle = @service.bundles.find_by(iid: params[:id])
    if Bundle::Delete.call(@bundle)
      redirect_to backoffice_service_path(@service), notice: "Bundle removed successfully"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def reindex_offer
    @service.offers.reindex if @service.offers.size > 1
  end

  def bundle_template
    temp = transform_attributes(permitted_attributes(Bundle))
    Bundle.new(temp.merge(service: @service, status: :published))
  end

  def transform_attributes(template)
    template.except(:from)
  end

  def find_service
    @service = Service.friendly.find(params[:service_id])
  end

  def find_bundle_and_authorize
    @bundle = @service.bundles.find_by(iid: params[:id])
    authorize(@bundle)
  end
end
