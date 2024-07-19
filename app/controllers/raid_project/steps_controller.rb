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
    step4: [raid_access_attributes: %i[id access_type statement_text statement_lang embargo_expiry _destroy]],
    step5: [:form_step]
  }.freeze

  def show
    step_state(step)
  end

  def update
    raid_id = params[:raid_project_id]
    saved_params = session[raid_id]
    if session[:wizard_action] == "create"
      raid_project_attrs = saved_params.merge permitted_step_attributes
      @raid_project = RaidProject.new(raid_project_attrs)
    else
      @raid_project = RaidProject.find_by(id: params[:raid_project_id])
      raid_project_attrs = saved_params.merge permitted_attributes(RaidProject)
      @raid_project.assign_attributes(raid_project_attrs)
    end

    if @raid_project.valid?
      session[raid_id] = raid_project_attrs
      redirect_to_next_step
    else
      render :show
    end
  end

  private

  def steps
    %i[step1 step2 step3 step4 step5]
  end

  def step
    params[:raid_project] ? params[:raid_project][:form_step].to_sym : "step1"
  end

  def next_step_template
    "raid_project/steps/#{next_step}"
  end

  def previous_step_template
    "raid_project/steps/#{previous_step}"
  end

  def redirect_to_next_step
    if current_step_index == 4
      finish_wizard_path
    else
      step_state(next_step)
      render turbo_stream:
               turbo_stream.replace("raid-form", partial: next_step_template, locals: { raid_project: @raid_project })
      # redirect_to raid_project_step_path(params[:raid_project_id], next_step)
    end
  end

  def finish_wizard_path
    saved_params = session[params[:raid_project_id]]
    session.delete params[:raid_project_id]

    if session[:wizard_action] == "create"
      @raid_project = RaidProject.new(permitted_attributes(RaidProject).merge(user: current_user).merge(saved_params))
      if @raid_project.valid?
        @raid_project.save!
      else
        render :show
      end
    else
      RaidProject.find_by(id: params[:raid_project_id]).update!(saved_params)
    end

    # redirect_to controller: :controller_name, action: :action_name ### namespace
    respond_to do |format|
      format.html { redirect_to raid_project_path(@raid_project), notice: "RAiD project was successfully created." }
    end
  end

  def current_step_index
    steps.index(step)
  end

  def next_step
    steps[current_step_index + 1] if current_step_index < 4
  end

  def previous_step
    steps[current_step_index - 1] if current_step_index > 0
  end

  def set_step1
    raise WizardActionError, "wizard_action parameter not set" if session[:wizard_action].nil?
    if session[:wizard_action] == "create"
      session[params[:raid_project_id]] ||= {}
      raid_project_attrs = session[params[:raid_project_id]] || {}
      @raid_project = RaidProject.new raid_project_attrs
      @raid_project.build_main_title if @raid_project.main_title.blank?
      @raid_project.build_main_description if @raid_project.main_description.blank?
    elsif session[:wizard_action] == "update"
      @raid_project = RaidProject.find_by(id: params[:raid_project_id])
      @raid_project.build_main_description if @raid_project.main_description.blank?
    else
      raise WizardActionError, "Unpermitted wizard_action parameter: #{session[:wizard_action]}"
    end
  end

  def set_step2
    if session[:wizard_action] == "create"
      @raid_project.contributors.build if @raid_project.contributors.blank?
    end
  end

  def set_step3
    if session[:wizard_action] == "create"
      @raid_project.raid_organisations.build if @raid_project.raid_organisations.blank?
    end
  end

  def set_step4
    if session[:wizard_action] == "create"
      @raid_project.build_raid_access if @raid_project.raid_access.blank?
    end
  end

  def set_step5

  end

  def step_state(step_to_set)
    method("set_#{step_to_set}").call
  end

  def find_or_create_raid_project
    @raid_project = RaidProject.find_by(id: params[:raid_project_id])
  end

  def permitted_step_attributes
    params.require(:raid_project).permit(:form_step, *RAID_FORM_STEPS[step]).merge(user: current_user)
  end
end
