# frozen_string_literal: true

class Admin::LeadSectionsController < Admin::ApplicationController
  before_action :find_and_authorize, only: %i[edit update destroy]

  def new
    @lead_section = LeadSection.new(slug: params[:slug])
    authorize(@lead_section)
  end

  def create
    @lead_section = LeadSection.new(permitted_attributes(LeadSection))
    authorize(@lead_section)

    if @lead_section.save
      redirect_to admin_leads_path, notice: "New lead section was created"
    else
      render :new, status: :bad_request
    end
  end

  def edit
  end

  def update
    if @lead_section.update(permitted_attributes(LeadSection))
      redirect_to admin_leads_path, notice: "Lead section was updated successfully"
    else
      render :edit, status: :bad_request
    end
  end

  def destroy
    @lead_section.destroy!

    redirect_to admin_leads_path, notice: "Lead section removed successfully"
  end

  private

  def find_and_authorize
    @lead_section = LeadSection.friendly.find(params["id"])
    authorize(@lead_section)
  end
end
