# frozen_string_literal: true

class Backoffice::DatasourcesController < Backoffice::ApplicationController
  before_action :find_and_authorize, only: %i[show edit update destroy]
  helper_method :cant_edit

  def index
    authorize(Datasource)
    @pagy, @datasources = pagy(policy_scope(Datasource).order(:name))
  end

  def show
  end

  def new
    @datasource = Datasource.new
    add_missing_nested_models(@datasource)
    authorize(@datasource)
  end

  def create
    @datasource = Datasource.new(permitted_attributes(Datasource))
    authorize(@datasource)

    if @datasource.save
      redirect_to backoffice_datasource_path(@datasource), notice: "New datasource created successfully"
    else
      add_missing_nested_models(@datasource)
      render :new, status: :bad_request
    end
  end

  def edit
    add_missing_nested_models(@datasource)
  end

  def update
    logo = ImageHelper.to_json(permitted_attributes(@datasource).delete(:logo))
    if Datasource::Update.call(@datasource, permitted_attributes(@datasource), logo)
      redirect_to backoffice_datasource_path(@datasource), notice: "Datasource updated successfully"
    else
      add_missing_nested_models(@datasource)
      render :edit, status: :bad_request
    end
  end

  def destroy
    @datasource.destroy!
    redirect_to backoffice_datasources_path, notice: "Datasource removed successfully"
  end

  private

  def find_and_authorize
    @datasource = Datasource.with_attached_logo.friendly.find(params[:id])
    authorize(@datasource)
  end

  def cant_edit(attribute)
    policy([:backoffice, @datasource]).permitted_attributes.exclude?(attribute)
  end

  def add_missing_nested_models(datasource)
    datasource.sources.build source_type: "eosc_registry" if datasource.sources.empty?
    datasource.build_main_contact if datasource.main_contact.blank?
    datasource.public_contacts.build if datasource.public_contacts.empty?
    datasource.link_multimedia_urls.build if datasource.link_multimedia_urls.blank?
    datasource.link_use_cases_urls.build if datasource.link_use_cases_urls.blank?
    datasource.persistent_identity_systems.build if datasource.persistent_identity_systems.blank?
    datasource.link_research_product_license_urls.build if datasource.link_research_product_license_urls.blank?
    if datasource.link_research_product_metadata_license_urls.blank?
      datasource.link_research_product_metadata_license_urls.build
    end
  end
end
