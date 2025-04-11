# frozen_string_literal: true

class Backoffice::CataloguesController < Backoffice::ApplicationController
  before_action :find_and_authorize, only: %i[show edit update destroy]

  def index
    authorize(Catalogue)
    @pagy, @catalogues = pagy(policy_scope(Catalogue).with_attached_logo.order(:name))
  end

  def show
  end

  def new
    @catalogue = Catalogue.new
    @catalogue.sources.build source_type: "eosc_registry"
    @catalogue.data_administrators << DataAdministrator.new(
      first_name: current_user.first_name,
      last_name: current_user.last_name,
      email: current_user.email
    )
    add_missing_nested_models
    authorize(@catalogue)
  end

  def edit
    add_missing_nested_models
  end

  def destroy
    respond_to do |format|
      if Catalogue::Delete.call(@catalogue)
        notice = "Catalogue removed successfully"
        flash.now[:notice] = notice
        format.html { redirect_to backoffice_catalogues_path(page: params[:page]), notice: notice }
      else
        alert = "This Catalogue has providers/services connected to it, therefore, it is not possible to remove it."
        flash.now[:alert] = alert
        format.html { redirect_to backoffice_catalogue_path(@catalogue, page: params[:page], alert: alert) }
      end
      format.turbo_stream
    end
  end

  def create
    permitted_attributes = permitted_attributes(Catalogue)
    @catalogue = Catalogue.new(**permitted_attributes, status: :unpublished)
    authorize(@catalogue)

    if valid_model_and_urls? && @catalogue.save(validate: false)
      flash[:notice] = "New catalogue created successfully"
      redirect_to backoffice_catalogue_path(@catalogue)
    else
      add_missing_nested_models
      render :new, status: :bad_request
    end
  end

  def update
    permitted_attributes = permitted_attributes(@catalogue)
    @catalogue.assign_attributes(permitted_attributes)

    if valid_model_and_urls? && @catalogue.save(validate: false)
      flash[:notice] = "Catalogue updated successfully"
      redirect_to backoffice_catalogue_path(@catalogue)
    else
      if @catalogue.public_contacts.present? && @catalogue.public_contacts.all?(&:marked_for_destruction?)
        @catalogue.public_contacts[0].reload
      end
      add_missing_nested_models
      render :edit, status: :bad_request
    end
  end

  private

  def find_and_authorize
    @catalogue = Catalogue.with_attached_logo.friendly.find(params[:id])
    authorize(@catalogue)
  end

  def add_missing_nested_models
    %i[sources public_contacts link_multimedia_urls data_administrators].each do |association|
      @catalogue.send(association).build if @catalogue.send(association).empty?
    end
    @catalogue.build_main_contact if @catalogue.main_contact.blank?
  end

  def valid_model_and_urls?
    valid = @catalogue.valid?
    if @catalogue.website_changed? && !UrlHelper.url_valid?(@catalogue.website)
      valid = false
      @catalogue.errors.add(:website, "isn't valid or website doesn't exist, please check URL")
    end

    invalid_multimedia =
      @catalogue.link_multimedia_urls.reject { |media| media.url.blank? || UrlHelper.url_valid?(media.url) }
    if @catalogue.link_multimedia_urls&.any?(&:changed?) && invalid_multimedia.present?
      valid = false
      @catalogue.errors.add(
        :link_multimedia_urls,
        "aren't valid or media don't exist, please check URLs: #{invalid_multimedia.map(&:url).join(", ")}"
      )
    end

    if @catalogue.errors.present? && @catalogue.errors.to_hash.length == 1 && @catalogue.errors["sources.eid"].present?
      @catalogue.errors.clear
      valid = true
    end

    valid
  end
end
