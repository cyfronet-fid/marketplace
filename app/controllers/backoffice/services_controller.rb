# frozen_string_literal: true

class Backoffice::ServicesController < Backoffice::ApplicationController
  include Service::Filterable
  include Service::Searchable
  include Service::Categorable
  include Service::Autocomplete

  before_action :find_and_authorize, only: [:show, :edit, :preview, :update, :destroy]
  before_action :sort_options
  before_action :ensure_in_session!, only: [:preview]
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
    session[:service] = @service.id
  end

  def new
    @service = Service.new
    @service.sources.build source_type: "eic"
    authorize(@service)
  end

  def preview
    session[:service] = @service.id
    @service = service_preview_template
  end

  def create
    template = service_template
    authorize(template)

    @service = Service::Create.new(template).call
    session[:service] = @service.id

    if @service.persisted?
      session.delete(:service)
      redirect_to backoffice_service_path(@service),
                  notice: "Service updated correctly"
    else
      render :new, status: :bad_request
    end
  end

  def edit
    if @service.sources.empty?
      @service.sources.build source_type: "eic"
    end
    session[:service] = @service.id
  end

  def update
    if Service::Update.new(@service, permitted_attributes(@service)).call
      redirect_to backoffice_service_path(@service),
                  notice: "Service updated correctly"
    else
      render :edit, status: :bad_request
    end
  end

  def destroy
    Service::Destroy.new(@service).call
    session.delete(:selected_service)
    redirect_to backoffice_services_path,
                notice: "Service destroyed"
  end

  protected

    def ensure_in_session!
      unless session[:service]
        redirect_to backoffice_service_path(@service),
                    alert: "Service request template not found"
      end
    end

  private
    def index_authorize
      authorize(Service)
    end

    def service_template
      Service.new(permitted_attributes(Service).merge(status: :draft))
    end

    def filter_classes
      super << Filter::UpstreamSource
    end

    def service_preview_template
      template = Service.new(session[:service])
      session[:service].
          merge(permitted_attributes(template))
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
