# frozen_string_literal: true

class Backoffice::ServicesController < Backoffice::ApplicationController
  before_action :find_and_authorize, only: [:show, :edit, :update, :destroy]

  def index
    authorize(Service)
    @services = policy_scope(Service).page(params[:page])
  end

  def show
  end

  def new
    @service = Service.new
    @service.sources.build source_type: "eic"
    authorize(@service)
  end

  def create
    template = service_template
    authorize(template)

    @service = Service::Create.new(template).call

    if @service.persisted?
      redirect_to backoffice_service_path(@service),
                  notice: "New service created sucessfully"
    else
      render :new, status: :bad_request
    end
  end

  def edit
    if @service.sources.empty?
      @service.sources.build source_type: "eic"
    end
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
    redirect_to backoffice_services_path,
                notice: "Service destroyed"
  end

  private
    def service_template
      Service.new(permitted_attributes(Service).merge(status: :draft))
    end

    def find_and_authorize
      @service = Service.friendly.find(params[:id])
      authorize(@service)
    end
end
