# frozen_string_literal: true

class RaidStepsController < ApplicationController
    include Wicked::Wizard

    RAID_FORM_STEPS = {
        step_1: [:start_date, :end_date, :main_title, :alternative_titles, :main_description, :alternative_descriptions],
        step_2: [:contributors],
        step_3: [:raid_organisations],
        step_4: [:raid_access],
        step_5: []
    }.freeze
  
    steps *RAID_FORM_STEPS.keys
  
    def show
        p '================='
        p "show"
        raid_project_attrs = Rails.cache.read params[:build_raid_project_id]
        p raid_project_attrs
        p wizard_path
        p next_wizard_path
        p steps
        @raid_project = RaidProject.new raid_project_attrs
        @raid_project.build_main_title
        @raid_project.contributors.build
        @raid_project.build_main_description
        @raid_project.raid_organisations.build
        @raid_project.build_raid_access
        render_wizard
    end

    def update
        p '++++++++++++++++++++++++++++==='
        p "update"
        raid_project_attrs = Rails.cache.read(params[:build_raid_project_id]).merge raid_project_params
        @raid_project = RaidProject.new raid_project_attrs

        if @raid_project.valid?
          Rails.cache.write params[:build_raid_project_id], raid_project_attrs
          redirect_to_next next_step
        else
          render_wizard 
        end
    end

   
  
    private
    def raid_project_params
        params.require(:raid_project).permit(RAID_FORM_STEPS[step]).merge(form_step: step.to_sym)
    end
  
    def finish_wizard_path
        raid_project_attrs = Rails.cache.read(params[:build_raid_project_id])
        @raid_project = RaidProject.new raid_project_attrs
        @raid_project.save!
        Rails.cache.delete params[:build_raid_project_id]
        raid_project_path(@raid_project)
      end
    end
