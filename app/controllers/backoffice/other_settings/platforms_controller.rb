# frozen_string_literal: true

class Backoffice::OtherSettings::PlatformsController < Backoffice::ApplicationController
  before_action :find_and_authorize, only: %i[show edit update destroy]

  def index
    authorize(Platform)
    @pagy, @platforms = pagy(policy_scope(Platform).order(:name))
  end

  def show
  end

  def new
    @platform = Platform.new
    authorize(@platform)
  end

  def create
    @platform = Platform.new(permitted_attributes(Platform))
    authorize(@platform)

    if @platform.save
      redirect_to backoffice_other_settings_platform_path(@platform), notice: "New platform created successfully"
    else
      render :new, status: :bad_request
    end
  end

  def edit
  end

  def update
    if @platform.update(permitted_attributes(@platform))
      redirect_to backoffice_other_settings_platform_path(@platform), notice: "Platform updated successfully"
    else
      render :edit, status: :bad_request
    end
  end

  def destroy
    @platform.destroy!
    redirect_to backoffice_other_settings_platforms_path, notice: "Platform removed successfully"
  end

  private

  def find_and_authorize
    @platform = Platform.find(params[:id])
    authorize(@platform)
  end
end
