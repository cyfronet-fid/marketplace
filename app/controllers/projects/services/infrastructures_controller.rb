# frozen_string_literal: true

class Projects::Services::InfrastructuresController < ApplicationController
  include Project::Authorize

  def destroy
    @project_item = @project.project_items.joins(project: :user).find_by!(iid: params[:service_id])

    authorize(@project_item, :destroy_infrastructure?)

    infrastructure = @project_item.infrastructure

    if infrastructure&.can_destroy?
      Infrastructure::DestroyJob.perform_later(infrastructure.id)
      flash[:notice] = _("Infrastructure destruction has been initiated. This may take a few minutes.")
    else
      flash[:alert] = _("Infrastructure cannot be destroyed at this time.")
    end

    redirect_to project_service_path(@project, @project_item)
  end
end
