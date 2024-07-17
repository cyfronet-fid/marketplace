# frozen_string_literal: true

class Backoffice::OtherSettings::ScientificDomainsController < Backoffice::ApplicationController
  before_action :find_and_authorize, only: %i[show edit update destroy]

  def index
    authorize(ScientificDomain)
    @scientific_domains = policy_scope(ScientificDomain).with_attached_logo
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
      redirect_to backoffice_other_settings_scientific_domain_path(@scientific_domain),
                  notice: "New scientific domain created successfully"
    else
      render :new, status: :bad_request
    end
  end

  def edit
  end

  def update
    if @scientific_domain.update(permitted_attributes(@scientific_domain))
      redirect_to backoffice_other_settings_scientific_domain_path(@scientific_domain),
                  notice: "Scientific domain updated successfully"
    else
      render :edit, status: :bad_request
    end
  end

  def destroy
    if @scientific_domain.descendant_ids.present?
      redirect_back fallback_location: backoffice_other_settings_scientific_domain_path(@scientific_domain),
                    alert:
                      "This scientific domain has successors connected to it,
                            therefore is not possible to remove it. If you want to remove it,
                            edit them so they are not associated with this scientific domain anymore"
    elsif @scientific_domain.services.present?
      redirect_back fallback_location: backoffice_other_settings_scientific_domain_path(@scientific_domain),
                    alert: "This scientific domain has services connected to it, remove associations to delete it."
    elsif @scientific_domain.providers.present?
      redirect_back fallback_location: backoffice_other_settings_scientific_domain_path(@scientific_domain),
                    alert: "This scientific domain has providers connected to it, remove associations to delete it."
    else
      @scientific_domain.destroy!
      redirect_to backoffice_other_settings_scientific_domains_path, notice: "Scientific Domain removed successfully"
    end
  end

  private

  def find_and_authorize
    @scientific_domain = ScientificDomain.find(params[:id])
    authorize(@scientific_domain)
  end
end
