# frozen_string_literal: true

class Backoffice::ProvidersController < Backoffice::ApplicationController
  include UrlHelper

  before_action :find_and_authorize, only: [:show, :edit, :update, :destroy]

  def index
    authorize(Provider)
    @pagy, @providers = pagy(policy_scope(Provider).order(:name))
  end

  def show
  end

  def new
    @provider = Provider.new
    @provider.sources.build source_type: "eic"
    @provider.data_administrators << DataAdministrator.new(
      first_name: current_user.first_name,
      last_name: current_user.last_name,
      email: current_user.email
    )
    @provider.build_main_contact
    @provider.public_contacts.build
    authorize(@provider)
  end

  def create
    permitted_attributes = permitted_attributes(Provider)
    @provider = Provider.new(permitted_attributes)
    authorize(@provider)

    if valid_model_and_urls? && @provider.save(validate: false)
      redirect_to backoffice_provider_path(@provider),
                  notice: "New provider created successfully"
    else
      render :new, status: :bad_request
    end
  end

  def edit
    add_missing_nested_models
  end

  def update
    permitted_attributes = permitted_attributes(@provider)
    @provider.assign_attributes(permitted_attributes)

    if valid_model_and_urls? && @provider.save(validate: false)
      redirect_to backoffice_provider_path(@provider),
                  notice: "Provider updated correctly"
    else
      if @provider.public_contacts.map { |contact| contact.marked_for_destruction? }.all?
        @provider.public_contacts[0].reload
      end
      if @provider.data_administrators.map { |admin| admin.marked_for_destruction? }.all?
        @provider.data_administrators[0].reload
      end
      render :edit, status: :bad_request
    end
  end

  def destroy
    @provider.destroy!
    redirect_to backoffice_providers_path,
                notice: "Provider destroyed"
  end

  private
    def find_and_authorize
      @provider = Provider.with_attached_logo.friendly.find(params[:id])
      authorize(@provider)
    end

    def add_missing_nested_models
      if @provider.sources.empty?
        @provider.sources.build source_type: "eic"
      end
      if @provider.data_administrators.blank?
        @provider.data_administrators.build
      end
      if @provider.main_contact.blank?
        @provider.build_main_contact
      end
      if @provider.public_contacts.blank?
        @provider.public_contacts.build
      end
    end

    def valid_model_and_urls?
      # More restricted validation in form instead of ActiveRecord itself
      # is related to loose validation of importing data from external services
      valid = @provider.valid?
      unless UrlHelper.url_valid?(@provider.website)
        valid = false
        @provider.errors.add(:website, "isn't valid or website doesn't exist, please check URL")
      end
      invalid_multimedia = @provider.multimedia.select { |media| !UrlHelper.url_valid?(media) }
      if invalid_multimedia.present?
        valid = false
        @provider.errors.add(
          :multimedia,
          "isn't valid or media doesn't exists, please check URLs: #{invalid_multimedia.join(", ")}"
        )
      end

      if @provider.errors.present? &&
        @provider.errors.to_hash.length == 1 &&
        @provider.errors["sources.eid"].present?
        valid = true
      end

      valid
    end

    def change_keys(hash, keys, new_value)
      keys.each { |k|  hash[k] = new_value if hash.has_key?(k) }
      hash.values.each { |v| change_keys(v, keys, new_value)  if v.class == Hash }
    end
end
