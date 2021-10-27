# frozen_string_literal: true

class Projects::Services::TimelinesController < ApplicationController
  include ProjectItem::Authorize

  def show
    load_timeline
    load_projects
  end

  private

  def load_projects
    @projects = policy_scope(Project).order(:name)
  end

  def load_timeline
    @statuses = @project_item.public_statuses.order(:updated_at)
  end
end
