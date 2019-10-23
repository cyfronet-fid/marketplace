# frozen_string_literal: true

class Backoffice::ResearchAreasController < Backoffice::ApplicationController
  before_action :find_and_authorize, only: [:show, :edit, :update, :destroy]
  before_action :parent_services, only: [:create, :update]
  before_action :leafs

  def index
    authorize(ResearchArea)
    @research_areas = policy_scope(ResearchArea)
  end

  def show
  end

  def new
    @label = t("backoffice.research_area.create")
    @research_area = ResearchArea.new
    authorize(@research_area)
  end

  def create
    @label = t("backoffice.research_area.create")
    @research_area = ResearchArea.new(permitted_attributes(ResearchArea))
    authorize(@research_area)
    @leafs.unshift(@research_area)
    @leafs.delete(@research_area&.parent)

    if params[:commit] != @label
      move_services(@research_area.parent, chosen)
    end

    if @research_area.save
      redirect_to backoffice_research_area_path(@research_area),
                  notice: "New research area created sucessfully"
    else
      render :new, status: :bad_request
    end
  end

  def edit
    @label = t("backoffice.research_area.update")
  end

  def update
    @label = t("backoffice.research_area.update")
    @leafs.unshift(@research_area)
    @leafs.delete(@research_area&.parent)

    new_parent = ResearchArea.find(params[:research_area][:parent_id])

    if params[:commit] != @label
      move_services(new_parent, chosen)
    end

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

    def parent_services
      @parent_services = ResearchArea.find_by(id: params[:research_area][:parent_id])&.services
    end

    def chosen
      params[:research_area][:move_ra_id].blank? ?
          @research_area : ResearchArea.find(params[:research_area][:move_ra_id])
    end

    def move_services(from, to)
      services = from.services
      services.each do |service|
        service.research_areas.delete(from)
      end
      services.each do |service|
        service.research_areas << to
        service.save!
      end
    end

    def leafs
      @leafs = ResearchArea.leafs.sort
    end
end
