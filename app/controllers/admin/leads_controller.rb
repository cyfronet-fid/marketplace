# frozen_string_literal: true

class Admin::LeadsController < Admin::ApplicationController
  before_action :find_and_authorize, only: %i[edit update destroy]

  def index
    @sections = LeadSection.includes(:leads).all
  end

  def new
    @section = LeadSection.find_by(slug: params["section"])
    @lead = Lead.new(lead_section: @section)
    authorize(@lead)
  end

  def create
    @lead = Lead.new(permitted_attributes(Lead))
    authorize(@lead)

    if @lead.save
      redirect_to admin_leads_path, notice: "New Lead created successfully"
    else
      render :new, status: :bad_request
    end
  end

  def edit
  end

  def update
    if @lead.update(permitted_attributes(Lead))
      redirect_to admin_leads_path, notice: "Lead was updated successfully"
    else
      render :edit, status: :bad_request
    end
  end

  def destroy
    @lead.destroy!
    redirect_to admin_leads_path, notice: "Lead removed successfully"
  end

  private

  def find_and_authorize
    @lead = Lead.find(params["id"])
    authorize(@lead)
  end
end
