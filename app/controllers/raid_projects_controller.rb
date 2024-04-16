# frozen_string_literal: true

class RaidProjectsController < ApplicationController
  acts_as_token_authentication_handler_for User, fallback: :exception
  before_action :authenticate_user!
  before_action :find_and_authorize, only: %i[show edit update destroy]

  def index
    @raid_projects = policy_scope(RaidProject)
    respond_to do |format|
      format.html 
      format.json { render json:  @raid_projects.map { |pi| serialize(pi) }  }
     end
  end

  def show
    @raid_project = RaidProject.find(params[:id])
    respond_to do |format|
      format.html 
      format.json { render json:  @raid_project, serializer: Api::V1::Raid::RaidProjectSerializer }
     end
  end

  def new
    @raid_project = RaidProject.new
    @raid_project.build_main_title
    @raid_project.contributors.build
    @raid_project.build_main_description
    @raid_project.raid_organisations.build
    @raid_project.build_raid_access

    respond_to do |format|
      format.html
      format.js { render_modal_form }
    end
  end

  def create
    @raid_project = RaidProject.new(permitted_attributes(RaidProject).merge(user: current_user))
    respond_to do |format|
      if @raid_project.save
        format.html { redirect_to raid_project_url(@raid_project), notice: "RAID project was successfully created." }
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def edit
    @raid_project.build_main_description if @raid_project.main_description.blank?
  end

  def update
    if @raid_project.update(permitted_attributes(@raid_project))
      redirect_to raid_project_path(@raid_project), notice: "RAID Project updated successfully"
    else
      render :edit, status: :bad_request
    end
  end

  def destroy
    @raid_project.destroy

    respond_to do |format|
      format.html { redirect_to raid_projects_url, notice: "RAID Project was successfully destroyed." }
    end
  end

  private

  def find_and_authorize
    @raid_project = RaidProject.find(params[:id])
    authorize(@raid_project)
  end

  def serialize(raid_project)
    Api::V1::Raid::RaidProjectSerializer.new(raid_project).as_json
  end
end
