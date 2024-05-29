# frozen_string_literal: true

class RaidProjectsController < ApplicationController
  acts_as_token_authentication_handler_for User, fallback: :exception
  before_action :authenticate_user!
  before_action :find_and_authorize, only: %i[show edit update destroy]

  def index
    @raid_projects = policy_scope(RaidProject)
    respond_to do |format|
      format.html
      format.json { render json: @raid_projects.map { |pi| serialize(pi) } }
    end
  end

  def show
    @raid_project = RaidProject.find(params[:id])
    respond_to do |format|
      format.html
      format.json { render json: @raid_project, serializer: Api::V1::Raid::RaidProjectSerializer }
    end
  end

  def new
    session[:raid_form_params] = {}
    @raid_project = RaidProject.new
    @raid_project.build_main_title
    
    @raid_project.build_main_description
    
    

    respond_to do |format|
      format.html
      format.js { render_modal_form }
    end
  end



  def create
    step = params[:raid_project][:step].to_i
    last_step_data = params[:raid_project].to_unsafe_h 
    if params[:raid_project]
      session[:raid_form_params].merge!(last_step_data)
    end
    p '======================='
    p step
    @raid_project = RaidProject.new(
      permitted_attributes(RaidProject).merge(user: current_user).merge(session[:raid_form_params]))
     
    case step
    when 1
      p step
      p session[:raid_form_params]
      @raid_project.contributors.build
      render turbo_stream: turbo_stream.replace(
        'form-container', partial: 'raid_projects/form/step_2', locals: { raid_project: @raid_project })
    when 2
      p step
      p session[:raid_form_params]
      @raid_project.raid_organisations.build
      render turbo_stream: turbo_stream.replace(
        'form-container', partial: 'raid_projects/form/step_3', locals: { raid_project: @raid_project })
    when 3
      p step
      p session[:raid_form_params]
      @raid_project.build_raid_access
      render turbo_stream: turbo_stream.replace(
        'form-container', partial: 'raid_projects/form/step_4', locals: { raid_project: @raid_project })
    when 4
      render turbo_stream: turbo_stream.replace(
        'form-container', partial: 'raid_projects/form/step_5', locals: { raid_project: @raid_project })
    when 5
      if @raid_project.save
        format.html { redirect_to raid_project_url(@raid_project), notice: "RAID project was successfully created." }
      else
        render turbo_stream: turbo_stream.replace(
          'form-container', partial: 'raid_projects/form/step_2', locals: { raid_project: @raid_project })
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
