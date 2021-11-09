# frozen_string_literal: true

class Backoffice::ServicesController < Backoffice::ApplicationController
  include Service::Searchable
  include Service::Categorable
  include Service::Autocomplete

  before_action :find_and_authorize, only: [:show, :edit, :update, :destroy]
  before_action :sort_options, :favourites
  before_action :load_query_params_from_session, only: :index
  prepend_before_action :index_authorize, only: :index
  helper_method :cant_edit

  def index
    if params["object_id"].present?
      if params["type"] == "provider"
        redirect_to backoffice_provider_path(Provider.friendly.find(params["object_id"]),
                                  anchor: ("offer-#{params["anchor"]}" if params["anchor"].present?))
      elsif params["type"] == "service"
        redirect_to backoffice_service_path(Service.friendly.find(params["object_id"]),
                                 anchor: ("offer-#{params["anchor"]}" if params["anchor"].present?))
      end
    end
    @services, @offers = search(scope)
    @pagy = Pagy.new_from_searchkick(@services, items: params[:per_page])
    @highlights = highlights(@services)
    @comparison_enabled = false
  end

  def show
    @offer = Offer.new(service: @service, status: :draft)
    @offers = @service.offers.published.order(:created_at)
    if current_user&.executive?
      @client = @client&.credentials&.expires_at.blank? ? Google::Analytics.new : @client
      @analytics = Analytics::PageViewsAndRedirects.new(@client).call(request.path)
    end
  end

  def new
    @service = Service.new(attributes_from_session || {})
    clear_session_attributes!
    @service.sources.build source_type: "eosc_registry"
    @service.build_main_contact
    @service.public_contacts.build
    authorize(@service)
  end

  def create
    template = service_template
    authorize(template)

    params[:commit] == "Preview" ? perform_preview(:new) : perform_create
  end

  def edit
    @service.assign_attributes(attributes_from_session || {})
    clear_session_attributes!
    add_missing_nested_models
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
    policy([:backoffice, @service]).permitted_attributes.exclude?(attribute)
  end

  private
    def preview_session_key
      @preview_session_key ||= "service-#{@service&.id}-preview"
    end

    def perform_preview(error_view)
      store_in_session!

      @service ||= Service.new(status: :draft)
      @service.assign_attributes(attributes_from_session)

      logo = session[preview_session_key]["logo"]
      if logo.present? && !ImageHelper.image_ext_permitted?(Rack::Mime::MIME_TYPES.invert[logo["type"]])
        @service.errors.add(:logo, ImageHelper.permitted_ext_message)
        render error_view, status: :bad_request
        return
      end

      if @service.valid?
        @offers = @service.offers.where(status: :published).order(:created_at)
        @related_services = @service.target_relationships
        @related_services_title = "Suggested compatible resources"
        if current_user&.executive?
          @client = @client&.credentials&.expires_at.blank? ? Google::Analytics.new : @client
          @analytics = Analytics::PageViewsAndRedirects.new(@client).call(request.path)
        end
        render :preview
      else
        render error_view, status: :bad_request
      end
    end

    def store_in_session!
      attributes = permitted_attributes(@service || Service)
      logo = attributes.delete(:logo)
      compact_attributes = attributes.each { |k, v| v.reject!(&:blank?) if v.instance_of? Array }
                                     .reject { |k, v| v.blank? }
      session[preview_session_key] = { "attributes" => compact_attributes }
      if logo
        session[preview_session_key]["logo"] = {
          "filename" => logo.original_filename,
          "base64" => ImageHelper.to_base_64(logo.path),
          "type" => logo.content_type
        }
      end
    end

    def clear_session_attributes!
      session[preview_session_key].delete("attributes") if session[preview_session_key]
    end

    def add_missing_nested_models
      if @service.sources.empty?
        @service.sources.build source_type: "eosc_registry"
      end
      if @service.main_contact.blank?
        @service.build_main_contact
      end
      if @service.public_contacts.blank?
        @service.public_contacts.build
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
                    notice: "New service created successfully"
      else
        add_missing_nested_models
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
        add_missing_nested_models
        render :edit, status: :bad_request
      end
    end

    def update_logo_from_session!
      logo = logo_from_session
      if logo
        blob, ext = ImageHelper.base_64_to_blob_stream(logo["base64"])
        path = ImageHelper.to_temp_file(blob, ext)
        @service.logo.attach(io: File.open(path), filename: logo["filename"]) if logo
      end
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
      @sort_options = [["by name A-Z", "sort_name"],
                       ["by name Z-A", "-sort_name"],
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

    def favourites
      @favourite_services = current_user&.favourite_services || Service.
        where(slug: Array(cookies[:favourites]&.split("&") || []))
    end

    def scope
      policy_scope(Service).with_attached_logo
    end

    def provider_scope
      policy_scope(Provider).with_attached_logo
    end
end
