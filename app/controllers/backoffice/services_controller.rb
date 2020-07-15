# frozen_string_literal: true

class Backoffice::ServicesController < Backoffice::ApplicationController
  include Service::Searchable
  include Service::Categorable
  include Service::Autocomplete

  before_action :find_and_authorize, only: [:show, :edit, :update, :destroy]
  before_action :sort_options
  prepend_before_action :index_authorize, only: :index
  helper_method :cant_edit

  def index
    if params["service_id"].present?
      redirect_to backoffice_service_path(Service.find(params["service_id"]),
                                          anchor: ("offer-#{params["anchor"]}" if params["anchor"].present?))
    end
    @services, @offers= search(scope)
    @highlights = highlights(@services)
    @comparison_enabled = false
  end

  def show
    @offer = Offer.new(service: @service, status: :draft)
    @offers = @service.offers.order(:created_at)
  end

  def new
    @service = Service.new(attributes_from_session || {})
    @service.sources.build source_type: "eic"
    authorize(@service)
  end

  def create
    template = service_template
    authorize(template)

    params[:commit] == "Preview" ? perform_preview(:new) : perform_create
  end

  def edit
    @service.assign_attributes(attributes_from_session || {})
    if @service.sources.empty?
      @service.sources.build source_type: "eic"
    end
  end

  def update
    params[:commit] == "Preview" ? perform_preview(:edit) : perform_update
  end

  def destroy
    Service::Destroy.new(@service).call
    redirect_to backoffice_services_path,
                notice: "Service destroyed"
  end

  def cant_edit(attribute)
    !policy([:backoffice, @service]).permitted_attributes.include?(attribute)
  end

  private
    def preview_session_key
      @preview_session_key ||= "service-#{@service&.id}-preview"
    end

    def perform_preview(error_view)
      store_in_session!

      @service ||= Service.new(status: :draft)
      @service.assign_attributes(attributes_from_session)

      if @service.valid?
        @offers = @service.offers.where(status: :published).order(:created_at)
        @related_services = @service.related_services

        render :preview
      else
        render error_view, status: :bad_request
      end
    end

    def store_in_session!
      attributes = permitted_attributes(@service || Service)
      logo = attributes.delete(:logo)
      session[preview_session_key] = { "attributes" => attributes }

      if logo
        logo_path = tmp_path
        FileUtils.cp logo.tempfile, logo_path

        session[preview_session_key]["logo"] = {
          "filename" => logo.original_filename,
          "path" => logo_path,
          "type" => logo.content_type
        }
      end
    end

    def attributes_from_session
      preview = session[preview_session_key]
      preview["attributes"] if preview
    end

    def logo_from_session
      preview = session[preview_session_key]
      preview["logo"] if preview
    end

    def perform_create
      @service = Service::Create.new(service_template).call

      if @service.persisted?
        update_logo_from_session!
        session.delete(preview_session_key)
        redirect_to backoffice_service_path(@service),
                    notice: "New service created sucessfully"
      else
        render :new, status: :bad_request
      end
    end

    def perform_update
      attributes = attributes_from_session || permitted_attributes(@service)

      if Service::Update.new(@service, attributes).call
        update_logo_from_session!
        session.delete(preview_session_key)
        redirect_to backoffice_service_path(@service),
                    notice: "Service updated correctly"
      else
        render :edit, status: :bad_request
      end
    end

    def update_logo_from_session!
      logo = logo_from_session
      @service.logo.attach(io: File.open(logo["path"]), filename: logo["filename"]) if logo
    end

    def index_authorize
      authorize(Service)
    end

    def service_template
      attributes = attributes_from_session || permitted_attributes(Service)

      Service.new(attributes.merge(status: :draft))
    end

    def filter_classes
      super + [Filter::UpstreamSource, Filter::Status]
    end

    def sort_options
      @sort_options = [["by name A-Z", "name"],
                       ["by name Z-A", "-name"],
                       ["draft first", "status"],
                       ["published first", "-status"],
                       ["by rate 1-5", "rating"],
                       ["by rate 5-1", "-rating"],
                       ["Best match", "_score"]]
    end

    def find_and_authorize
      @service = Service.friendly.find(params[:id])
      authorize(@service)
    end

    def scope
      policy_scope(Service).with_attached_logo
    end

    def tmp_path
      tmp_logo = Tempfile.new
      tmp_path = tmp_logo.path
      tmp_logo.close

      tmp_path
    end
end
