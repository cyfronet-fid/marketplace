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
    step_to_set = params[:step] || (session[:wizard_action] == "update" ? "step5" : step)
    step_state(step_to_set)
    render template: "raid_project/steps/show", locals: { step: step_to_set }
  end

  def update
    action = params[:commit]
    saved_params = session[:current_raid]
    raid_project_attrs = saved_params.merge permitted_step_attributes
    @raid_project = RaidProject.new(raid_project_attrs)
    if @raid_project.valid?
      session[:current_raid] = raid_project_attrs
      redirect_to_next_step(action)
    elsif action == "Back"
      redirect_to_next_step(action)
    else
      render :show, locals: { step: step }
    end
  end

  private

  def steps
    %i[step1 step2 step3 step4 step5]
  end

  def step
    params[:raid_project] ? params[:raid_project][:form_step].to_sym : "step1"
  end

  def next_step_template(step_to_set)
    "raid_project/steps/#{step_to_set}"
  end

  def redirect_to_next_step(action)
    step_to_set = action == "Back" ? prev_step : next_step
    if step_to_set.nil? # TODO: !!!!! wrong pattern
      finish_wizard_path
    else
      step_state(step_to_set)
      render turbo_stream:
               turbo_stream.replace(
                 "raid-form",
                 partial: next_step_template(step_to_set),
                 locals: {
                   raid_project: @raid_project,
                   step: step_to_set
                 }
               )
    end
  end

  def finish_wizard_path
    token = RaidProject::RaidLogin.new.call
    raid_id = session[:raid_project_id]
    saved_params = session[:current_raid]
    session.delete raid_id
    @raid_project = RaidProject.new(permitted_attributes(RaidProject).merge(user: current_user).merge(saved_params))
    if @raid_project.valid?
      serialized_raid_project = serialize(@raid_project)
      if session[:wizard_action] == "create"
        response = RaidProject::PostRaid.new(serialized_raid_project, token).call
        notice =
          response[:status] < 400 ? "RAiD project was successfully created." : "RAiD project is currently unavailable."
      else
        response = RaidProject::UpdateRaid.new(serialized_raid_project, token, raid_id).call
        notice =
          response[:status] < 400 ? "RAiD project was successfully updated." : "RAiD project is currently unavailable."
      end
      respond_to { |format| format.html { redirect_to raid_projects_path, notice: notice } }
    else
      render :show
    end
  end

  def current_step_index
    steps.index(step)
  end

  def next_step
    steps[current_step_index + 1] if current_step_index < 4
  end

  def prev_step
    steps[current_step_index - 1] if current_step_index.positive?
  end

  def set_step1
    session[:raid_project_id]
    raise WizardActionError, "wizard_action parameter not set" if session[:wizard_action].nil?
    @raid_project = raid_data
    @raid_project.build_main_title if @raid_project.main_title.blank?
    @raid_project.build_main_description if @raid_project.main_description.blank?
  end

  def set_step2
    @raid_project = raid_data
    @raid_project.contributors.build if session[:wizard_action] == "create" && @raid_project.contributors.blank?
  end

  def set_step3
    @raid_project = raid_data
    if session[:wizard_action] == "create" && @raid_project.raid_organisations.blank?
      @raid_project.raid_organisations.build
    end
  end

  def set_step4
    @raid_project = raid_data
    @raid_project.build_raid_access if session[:wizard_action] == "create" && @raid_project.raid_access.blank?
  end

  def set_step5
    @raid_project = raid_data
    @raid_project
  end

  def step_state(step_to_set)
    method("set_#{step_to_set}").call
  end

  def permitted_step_attributes
    params.require(:raid_project).permit(:form_step, *RAID_FORM_STEPS[step]).merge(user: current_user)
  end

  def serialize(raid_project)
    Api::V1::Raid::RaidProjectSerializer.new(raid_project)
  end

  def raid_data
    saved_params = session[:current_raid]
    @raid_project = RaidProject.new(saved_params.merge(user: current_user))
  end
end
