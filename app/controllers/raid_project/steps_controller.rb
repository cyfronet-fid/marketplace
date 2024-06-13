# frozen_string_literal: true

class RaidProject::StepsController < ApplicationController

  class WizardActionError < StandardError
  end

  RAID_FORM_STEPS = {
    step1: [
      :start_date,
      :end_date,
      :form_step,
      main_title_attributes: %i[id text language start_date end_date],
      alternative_titles_attributes: %i[id text language start_date end_date _destroy],
      main_description_attributes: %i[id text language],
      alternative_descriptions_attributes: %i[id text language _destroy]
    ],
    step2: [
      contributors_attributes: [
        :id,
        :pid,
        :pid_type,
        :leader,
        :contact,
        :_destroy,
        [roles: []],
        position_attributes: %i[id pid start_date end_date]
      ]
    ],
    step3: [
      raid_organisations_attributes: [:id, :pid, :name, :_destroy, position_attributes: %i[id pid start_date end_date]]
    ],
    step4: [
      raid_access_attributes: %i[id access_type statement_text statement_lang embargo_expiry _destroy]
    ],
    step5: [:form_step]
  }.freeze


  def show
    set_step_state(step)
  end

  def update
    raid_id = params[:raid_project_id]
    saved_params = session[raid_id]
    
    raid_project_attrs = saved_params.merge raid_project_params

    @raid_project = RaidProject.new(raid_project_attrs)
    
    if @raid_project.valid?
      session[raid_id] = raid_project_attrs
      redirect_to_next_step
    else
      render :show 
    end
  end
  

  private

  def raid_project_params
    params.require(:raid_project).permit(:form_step, *RAID_FORM_STEPS[step]).merge(user: current_user)
  end

  def serialize(raid_project)
    Api::V1::Raid::RaidWizardSerializer.new(raid_project).as_json
  end

  def steps
    RAID_FORM_STEPS.keys
  end

  def step
    params[:id].to_sym
  end

  def next_step_template
    "raid_project/steps/#{next_step}"
  end

  def redirect_to_next_step
    if current_step_index == 4
      finish_wizard_path
    else
      project = set_step_state(next_step)
      render turbo_stream: turbo_stream.replace(
        'raid-form', partial: next_step_template, locals: { :@raid_project => project })
      # redirect_to raid_project_step_path(params[:raid_project_id], next_step)
    end
  end

  def deserliaze(obj)
    ActiveModelSerializers::Deserialization.jsonapi_parse!(obj.to_h)
  end

  def finish_wizard_path
    saved_params = session[params[:raid_project_id]]
    @raid_project = RaidProject.new(permitted_attributes(RaidProject).merge(user: current_user).merge(saved_params))
    unless @raid_project.valid?
      p @raid_project.errors
      render :show
    end

    if session[:wizard_action] == "create"
      @raid_project.save!
    else
      p '=============================='
      p saved_params.keys    
      raid_project = RaidProject.find_by(id: params[:raid_project_id])
      raid_project.update!(saved_params)
    end

    session.delete params[:raid_project_id]
    # redirect_to controller: :controller_name, action: :action_name ### namespace
    respond_to do |format|
      format.html { redirect_to @raid_project, notice: "RAID project was successfully created." }
    end
  end

  def current_step_index
    steps.index(step)
  end

  def next_step
    steps[current_step_index+1] if current_step_index < 4    
  end

  def set_step1
    if session[:wizard_action].nil?
      raise WizardActionError, "wizard_action parameter not set"
    end
    if session[:wizard_action] == "create"
      set_step1_create
    elsif session[:wizard_action] == "update"
      set_step1_update
    else
      raise WizardActionError, "Unpermitted wizard_action parameter: #{session[:wizard_action]}"
    end
  end
  

  def set_step1_create
    raid_project_attrs = session[params[:raid_project_id]] || {}
    @raid_project = RaidProject.new raid_project_attrs
    @raid_project.build_main_title
    @raid_project.build_main_description
  end

  def set_step1_update
    @raid_project = RaidProject.find_by(id: params[:raid_project_id])
    raid_project_attrs = serialize @raid_project
    session[params[:raid_project_id]] = raid_project_attrs
    @raid_project.build_main_description if @raid_project.main_description.blank?
  end


  def set_step2
    raid_project_attrs = session[params[:raid_project_id]]
    if session[:wizard_action] == "create"
      @raid_project = RaidProject.new raid_project_attrs
      @raid_project.contributors.build
    end
  end

  def set_step3
    raid_project_attrs = session[params[:raid_project_id]]
    if session[:wizard_action] == "create"
      @raid_project = RaidProject.new raid_project_attrs
      @raid_project.raid_organisations.build
    end
  end

  def set_step4
    raid_project_attrs = session[params[:raid_project_id]]
    if session[:wizard_action] == "create"
      @raid_project = RaidProject.new raid_project_attrs
      @raid_project.build_raid_access
    end
  end

  def set_step5
    raid_project_attrs = session[params[:raid_project_id]]
    if session[:wizard_action] == "create"
      @raid_project = RaidProject.new raid_project_attrs
    end
  end

  def set_step_state(step_to_set)
    method("set_#{step_to_set}").call
  end

end
