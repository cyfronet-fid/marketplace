# frozen_string_literal: true

class Backoffice::ServicesController < Backoffice::ApplicationController
  include Service::Autocomplete
  include Service::Categorable
  include Service::Monitorable
  include Service::Recommendable
  include Service::Searchable
  include Service::Monitorable
  include Backoffice::ServicesSessionHelper

  before_action :find_and_authorize, only: %i[show edit update destroy]
  before_action :sort_options, :favourites
  before_action :load_query_params_from_session, only: :index
  prepend_before_action(only: [:index]) { authorize(Service) }
  helper_method :cant_edit

  def index
    if params["object_id"].present?
      case params["type"]
      when "provider"
        redirect_to backoffice_provider_path(
                      Provider.friendly.find(params["object_id"]),
                      anchor: ("offer-#{params["anchor"]}" if params["anchor"].present?)
                    )
      when "service"
        redirect_to backoffice_service_path(
                      Service.friendly.find(params["object_id"]),
                      anchor: ("offer-#{params["anchor"]}" if params["anchor"].present?)
                    )
      when "datasource"
        redirect_to backoffice_service_path(Datasource.friendly.find(params["object_id"]))
      end
    end
    @services, @offers = search(scope)
    begin
      @pagy = Pagy.new_from_searchkick(@services, items: params[:per_page])
    rescue Pagy::OverflowError
      params[:page] = 1
      @services, @offers = search(scope)
      @pagy = Pagy.new_from_searchkick(@services, items: params[:per_page])
    end
    @highlights = highlights(@services)
    @comparison_enabled = false
  end

  def show
    @service.monitoring_status = fetch_status(@service.pid)
    @offer = Offer.new(service: @service, status: :draft)
    @offers = policy_scope(@service.offers).order(:created_at)
    @bundles = policy_scope(@service.bundles).order(:created_at)
    @similar_services = fetch_similar(@service.id, current_user&.id)
    @related_services = @service.target_relationships
  end

  def new
    @service = Service.new(temp_attrs || {})
    remove_temp_data!(save_logo: true)
    add_missing_nested_models(@service)
    authorize(@service)
  end

  def create
    attrs = temp_attrs || permitted_attributes(Service)
    if params[:commit] == "Preview"
      @service = Service.new(**attrs, status: :draft)
      perform_preview(:new)
      return
    end

    @service = Service::Create.call(Service.new(**attrs, status: :draft), temp_logo)
    if @service.invalid?
      add_missing_nested_models(@service)
      render :new, status: :bad_request unless @service.persisted?
      return
    end

    remove_temp_data!
    redirect_to backoffice_service_path(@service), notice: "New service created successfully"
  end

  def edit
    @service.assign_attributes(temp_attrs || {})
    remove_temp_data!(save_logo: true)
    add_missing_nested_models(@service)
  end

  def update
    attrs = temp_attrs || permitted_attributes(@service)
    if params[:commit] == "Preview"
      @service.assign_attributes(attrs) if attrs
      perform_preview(:edit)
      return
    end

    unless Service::Update.call(@service, attrs, temp_logo)
      render :edit, status: :bad_request
      return
    end
    @service.store_analytics
    remove_temp_data!
    redirect_to backoffice_service_path(@service), notice: "Service updated successfully"
  end

  def destroy
    Service::Destroy.new(@service).call
    redirect_to backoffice_services_path, notice: "Service removed successfully"
  end

  def cant_edit(attribute)
    policy([:backoffice, @service]).permitted_attributes.exclude?(attribute)
  end

  private

  def add_missing_nested_models(service)
    service.sources.build source_type: "eosc_registry" if service.sources.empty?
    service.build_main_contact if service.main_contact.blank?
    service.public_contacts.build if service.public_contacts.empty?
    service.link_multimedia_urls.build if service.link_multimedia_urls.blank?
    service.link_use_cases_urls.build if service.link_use_cases_urls.blank?
    service.link_research_product_license_urls.build if service.link_research_product_license_urls.blank?
    if service.link_research_product_metadata_license_urls.blank?
      service.link_research_product_metadata_license_urls.build
    end
    service.persistent_identity_systems.build if service.persistent_identity_systems.blank?
  end

  def perform_preview(error_view)
    store_attrs!(permitted_attributes(@service || Service))

    if @service.public_contacts.present? && @service.public_contacts.all?(&:marked_for_destruction?)
      @service.public_contacts[0].reload
    end

    if @service.invalid?
      remove_temp_data!
      add_missing_nested_models(@service)
      render error_view, status: :bad_request
      return
    end

    unless valid_logo?(temp_logo)
      @service.errors.add(:logo, ImageHelper::PERMITTED_EXT_MESSAGE)
      render error_view, status: :bad_request
      return
    end

    @offers = @service.offers.where(status: :published).order(:created_at).reject(&:bundle?)
    @related_services = @service.target_relationships
    @bundles = policy_scope(@service.bundles.published)
    @bundled = @service.offers.select(&:bundled?) ? @service.offers.select(&:bundled?).map(&:bundles).flatten.uniq : []
    render :preview
  end

  def valid_logo?(logo)
    logo.blank? || ImageHelper.image_ext_permitted?(Rack::Mime::MIME_TYPES.invert[logo["type"]])
  end

  def filter_classes
    super + [Filter::UpstreamSource, Filter::Status]
  end

  def find_and_authorize
    @service = Service.friendly.find(params[:id])
    authorize(@service)
  end

  def favourites
    @favourite_services =
      current_user&.favourite_services || Service.where(slug: Array(cookies[:favourites]&.split("&") || []))
  end

  def sort_options
    @sort_options = [
      ["by name A-Z", "sort_name"],
      ["by name Z-A", "-sort_name"],
      ["draft first", "status"],
      ["published first", "-status"],
      ["by rate 1-5", "rating"],
      ["by rate 5-1", "-rating"],
      ["Best match", "_score"]
    ]
  end

  def scope
    policy_scope(Service).with_attached_logo
  end

  def provider_scope
    policy_scope(Provider).with_attached_logo
  end

  def datasource_scope
    policy_scope(Datasource).with_attached_logo
  end
end
