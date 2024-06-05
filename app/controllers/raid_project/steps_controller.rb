# frozen_string_literal: true

class RaidProject::StepsController < ApplicationController
  include Wicked::Wizard

  @@existing = false
  @@building_project_valid = false

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
      :form_step,
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
      :form_step,
      raid_organisations_attributes: [:id, :pid, :name, :_destroy, position_attributes: %i[id pid start_date end_date]]
    ],
    step4: [
      :form_step,
      raid_access_attributes: %i[id access_type statement_text statement_lang embargo_expiry _destroy]
    ],
    step5: [:form_step]
  }.freeze

  steps(*RAID_FORM_STEPS.keys)

  def show
    obj_form_db = RaidProject.where(:id => params[:raid_project_id]).first if params[:raid_project_id]
    if obj_form_db.nil?
      show_new_object
    else
      @@existing = true
      show_existing_object
    end
  end

  def show_existing_object
    @raid_project = RaidProject.find(params[:raid_project_id])
    @raid_project.build_main_description if @raid_project.main_description.blank?
    render_wizard 
  end

  def show_new_object
    raid_project_attrs = Rails.cache.read params[:raid_project_id] if params[:raid_project_id]
   
    @raid_project = RaidProject.new raid_project_attrs
    @raid_project.build_main_title
    @raid_project.contributors.build
    @raid_project.build_main_description
    @raid_project.raid_organisations.build
    @raid_project.build_raid_access
    render_wizard
  end

  def update
   
    saved_params = Rails.cache.read(params[:raid_project_id])
    raid_project_attrs = saved_params.merge raid_project_params

    if @@existing
      p '==========================='
      @raid_project = RaidProject.find(params[:raid_project_id])
      p 'found'
      temp_pr =  RaidProject.new(raid_project_attrs)
      p '+++++++++++++++++++++++++'
      @@building_project_valid =temp_pr.valid?
    else
      @raid_project = RaidProject.new(raid_project_attrs)
      @@building_project_valid = @raid_project.valid?
    end
    if @@building_project_valid
      Rails.cache.write params[:raid_project_id], raid_project_attrs
      redirect_to_next next_step
    else
      render_wizard
    end
  end

  private

  def raid_project_params
    params.require(:raid_project).permit(RAID_FORM_STEPS[step]).merge(form_step: step.to_sym).merge(user: current_user)
  end

  def finish_wizard_path
    raid_project_attrs = Rails.cache.read(params[:raid_project_id])
    # existing = saved_params.delete(:existing)
   
    @raid_project = RaidProject.new raid_project_attrs
    @raid_project.save!
    Rails.cache.delete params[:raid_project_id]
    raid_project_path(@raid_project)
  end
end
