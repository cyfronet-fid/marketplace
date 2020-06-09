# frozen_string_literal: true

class Backoffice::ScientificDomainsController < Backoffice::ApplicationController
  before_action :find_and_authorize, only: [:show, :edit, :update, :destroy]

  def index
    authorize(ScientificDomain)
    @scientific_domains  = policy_scope(ScientificDomain)
  end

  def show
  end

  def new
    @scientific_domain = ScientificDomain.new
    authorize(@scientific_domain)
  end

  def create
    @scientific_domain = ScientificDomain.new(permitted_attributes(ScientificDomain))
    authorize(@scientific_domain)

    if @scientific_domain.save
      redirect_to backoffice_scientific_domain_path(@scientific_domain),
                  notice: "New scientific_domain created sucessfully"
    else
      render :new, status: :bad_request
    end
  end

  def edit
  end

  def update
    if @scientific_domain.update(permitted_attributes(@scientific_domain))
      redirect_to backoffice_scientific_domain_path(@scientific_domain),
                  notice: "Scientific domain updated correctly"
    else
      render :edit, status: :bad_request
    end
  end

  def destroy
    @scientific_domain.destroy!
    redirect_to backoffice_scientific_domains_path,
                notice: "Scientific domain destroyed"
  end

  private
    def find_and_authorize
      @scientific_domain = ScientificDomain.find(params[:id])
      authorize(@scientific_domain)
    end
end
