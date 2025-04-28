# frozen_string_literal: true

class RaidProjectsController < ApplicationController
  acts_as_token_authentication_handler_for User, fallback: :exception
  before_action :authenticate_user!

  def index
    return head 404 unless Rails.configuration.raid_on
    token = RaidProject::RaidLogin.new.call
    response = RaidProject::GetRaids.new(token).call

    if response[:status] > 399
      @raid_projects = []
      render :index, notice: "RAiD service is temporary unavailable. Please try again later."
    else
      @raid_projects = response[:data].map { |project| deserialize(project) }
      respond_to do |format|
        format.html
        format.json { render json: @raid_projects.map { |pi| serialize(pi) } }
      end
    end
  end

  def show
    head 404 unless Rails.configuration.raid_on
  end

  def new
    return head 404 unless Rails.configuration.raid_on
    raid_builder_key = Random.urlsafe_base64(6)
    session[:raid_project_id] = raid_builder_key
    session[:wizard_action] = "create"
    session[:current_raid] = {}
    session[:raid_access_token] = RaidProject::RaidLogin.new.call
    redirect_to raid_project_steps_path(raid_builder_key, "step1")
  end

  def create
    @raid_project = RaidProject.new(permitted_attributes(RaidProject).merge(user: current_user))
    respond_to do |format|
      if @raid_project.save
        format.html { redirect_to raid_project_url(@raid_project), notice: "RAiD project was successfully created." }
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def edit
    return head 404 unless Rails.configuration.raid_on
    pid = params[:id]
    token = RaidProject::RaidLogin.new.call
    response = RaidProject::GetRaid.new(token, pid).call
    render :index if response[:status] > 399
    local_raid = RaidProject.translate_incoming_json(response[:data])
    session[:current_raid] = local_raid
    session[:raid_project_id] = pid
    session[:wizard_action] = "update"
    redirect_to raid_project_steps_path
  end

  def update
    if @raid_project.update(permitted_attributes(@raid_project))
      redirect_to raid_project_path(@raid_project), notice: "RAiD Project updated successfully"
    else
      render :edit, status: :bad_request
    end
  end

  private

  def find_and_authorize
    @raid_project = RaidProject.find(params[:id])
    authorize(@raid_project)
  end

  def deserialize(incoming_project)
    RaidProject.new(RaidProject.translate_incoming_json(incoming_project))
  end

  def serialize(raid_project)
    Api::V1::Raid::RaidProjectSerializer.new(raid_project).as_json
  end
end
