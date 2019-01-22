# frozen_string_literal: true

class Backoffice::ResearchAreasController < Backoffice::ApplicationController
  before_action :find_and_authorize, only: [:show, :edit, :update, :destroy]

  def index
    authorize(ResearchArea)
    @research_areas = policy_scope(ResearchArea).page(params[:page])
  end

  def show
  end

  def new
    @research_area = ResearchArea.new
    authorize(@research_area)
  end

  def create
    @research_area = ResearchArea.new(permitted_attributes(ResearchArea))
    authorize(@research_area)

    if @research_area.save
      redirect_to backoffice_research_area_path(@research_area),
                  notice: "New research_area created sucessfully"
    else
      render :new, status: :bad_request
    end
  end

  def edit
  end

  def update
    if @research_area.update(permitted_attributes(@research_area))
      redirect_to backoffice_research_area_path(@research_area),
                  notice: "Research area updated correctly"
    else
      render :edit, status: :bad_request
    end
  end

  def destroy
    @research_area.destroy!
    redirect_to backoffice_research_areas_path,
                notice: "Research area destroyed"
  end

  private
    def find_and_authorize
      @research_area = ResearchArea.find(params[:id])
      authorize(@research_area)
    end
end
