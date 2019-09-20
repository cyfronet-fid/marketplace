# frozen_string_literal: true

class Backoffice::ServicesController < Backoffice::ApplicationController
  include Service::Filterable
  include Service::Searchable
  include Service::Categorable
  include Service::Autocomplete

  before_action :find_and_authorize, only: [:show, :edit, :update, :destroy]
  before_action :sort_options
  prepend_before_action :index_authorize, only: :index

  def index
    if params["service_id"].present?
      redirect_to [:backoffice, Service.find(params["service_id"])]
    end
    @services = search_and_filter(scope)
    @highlights = highlights(@services)
  end

  def show
    @offer = Offer.new(service: @service, status: :draft)
  end

  def new
    @service = Service.new(session[preview_session_key] || {})
    @service.sources.build source_type: "eic"
    authorize(@service)
  end

  def create
    template = service_template
    authorize(template)

    params[:commit] == "Preview" ? perform_preview : perform_create
  end

  def edit
    @service.assign_attributes(session[preview_session_key] || {})
    if @service.sources.empty?
      @service.sources.build source_type: "eic"
    end
  end

  def update
    params[:commit] == "Preview" ? perform_preview : perform_update
  end

  def destroy
    Service::Destroy.new(@service).call
    redirect_to backoffice_services_path,
                notice: "Service destroyed"
  end

  private

    def preview_session_key
      "service-#{@service&.id}-preview"
    end

    def perform_preview
      session[preview_session_key] = permitted_attributes(@service || Service)

      @service ||= Service.new(status: :draft)
      @service.assign_attributes(session[preview_session_key])
      @offers = @service.offers.where(status: :published)
      @related_services = @service.related_services

      render :preview
    end

    def perform_create
      @service = Service::Create.new(service_template).call
      session.delete(preview_session_key)

      puts "service errors >>>>>>>>>>>>>>>>>> #{@service.errors.inspect}"

      if @service.persisted?
        redirect_to backoffice_service_path(@service),
                    notice: "New service created sucessfully"
      else
        render :new, status: :bad_request
      end
    end

    def perform_update
      attributes = session[preview_session_key] || permitted_attributes(@service)
      session.delete(preview_session_key)

      if Service::Update.new(@service, attributes).call
        redirect_to backoffice_service_path(@service),
                    notice: "Service updated correctly"
      else
        render :edit, status: :bad_request
      end
    end

    def index_authorize
      authorize(Service)
    end

    def service_template
      attributes = session[preview_session_key] || permitted_attributes(Service)

      Service.new(attributes.merge(status: :draft))
    end

    def sort_options
      @sort_options = [["by name A-Z", "title"],
                       ["by name Z-A", "-title"],
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
end
