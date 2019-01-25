# frozen_string_literal: true

class Backoffice::ProvidersController < Backoffice::ApplicationController
  before_action :find_and_authorize, only: [:show, :edit, :update, :destroy]

  def index
    authorize(Provider)
    @providers = policy_scope(Provider).page(params[:page]).order(:name)
  end

  def show
  end

  def new
    @provider = Provider.new
    authorize(@provider)
  end

  def create
    @provider = Provider.new(permitted_attributes(Provider))
    authorize(@provider)

    if @provider.save
      redirect_to backoffice_provider_path(@provider),
                  notice: "New provider created sucessfully"
    else
      render :new, status: :bad_request
    end
  end

  def edit
  end

  def update
    if @provider.update(permitted_attributes(@provider))
      redirect_to backoffice_provider_path(@provider),
                  notice: "Provider updated correctly"
    else
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
      @provider = Provider.find(params[:id])
      authorize(@provider)
    end
end
