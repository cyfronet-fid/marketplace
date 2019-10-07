# frozen_string_literal: true

class Backoffice::ResearchAreasController < Backoffice::ApplicationController
  before_action :find_and_authorize, only: [:show, :edit, :update, :destroy]
  before_action :parent_services, only: [:create, :update]

  def index
    authorize(ResearchArea)
    @research_areas = policy_scope(ResearchArea)
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

    if params[:commit] == "other_for_parent"
      move_services(@research_area.parent, other_for(@research_area.parent))
    elsif params[:commit] == "other"
      move_services(@research_area.parent, other)
    elsif params[:commit] == "current"
      move_services(@research_area.parent, @research_area)
    end

    if @research_area.save
      redirect_to backoffice_research_area_path(@research_area),
                  notice: "New research area created sucessfully"
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

    def parent_services
      @parent_services = ResearchArea.find_by(id: params[:research_area][:parent_id])&.services
    end

    def other_for(research_area)
      ResearchArea.find_by(name: "Other for #{research_area.name.downcase}") ||
          ResearchArea.create(name: "Other for #{research_area.name.downcase}", parent: research_area)
    end

    def other
      ResearchArea.find_by(name: "Other") || ResearchArea.create(name: "Other")
    end

    def move_services(from, to)
      from.services.each do |service|
        service.research_areas.delete(from)
        service.research_areas << to
        service.save!
      end
    end
end
