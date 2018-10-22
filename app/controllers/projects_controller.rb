# frozen_string_literal: true

class ProjectsController < ApplicationController
  before_action :authenticate_user!

  def index
    @projects = policy_scope(Project).order(:name).includes(:project_items)
  end
end
