# frozen_string_literal: true

class Services::OrderingConfiguration::BundlesController < Services::OrderingConfiguration::ApplicationController
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
      redirect_to service_ordering_configuration_path(@service), notice: "New bundle created successfully"
    else
      render :new, status: :bad_request
    end
  end

  def edit
  end

  def update
    template = permitted_attributes(Bundle.new)
    if Bundle::Update.call(@bundle, transform_attributes(template))
      redirect_to service_ordering_configuration_path(@service), notice: "Bundle updated successfully"
    else
      render :edit, status: :bad_request
    end
  end

  def destroy
    @bundle = @service.bundles.find_by(iid: params[:id])
    Bundle::Delete.call(@bundle)
    redirect_to service_ordering_configuration_path(@service), notice: "Bundle removed successfully"
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
    # template["parameters_attributes"] = [] if template["parameters_attributes"].blank?
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
