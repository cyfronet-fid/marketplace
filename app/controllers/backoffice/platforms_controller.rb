# frozen_string_literal: true

class Backoffice::PlatformsController < Backoffice::ApplicationController
  before_action :find_and_authorize, only: [:show, :edit, :update, :destroy]

  def index
    authorize(Platform)
    @platforms = policy_scope(Platform).page(params[:page]).order(:name)
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
      redirect_to backoffice_platform_path(@platform),
                  notice: "New platform created sucessfully"
    else
      render :new, status: :bad_request
    end
  end

  def edit
  end

  def update
    if @platform.update(permitted_attributes(@platform))
      redirect_to backoffice_platform_path(@platform),
                  notice: "Platform updated correctly"
    else
      render :edit, status: :bad_request
    end
  end

  def destroy
    @platform.destroy!
    redirect_to backoffice_platforms_path,
                notice: "Platform destroyed"
  end

  private
    def find_and_authorize
      @platform = Platform.find(params[:id])
      authorize(@platform)
    end
end
