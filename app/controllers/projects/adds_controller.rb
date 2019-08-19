# frozen_string_literal: true

class Projects::AddsController < ApplicationController
  include Project::Authorize

  def create
    session[:selected_project] = @project.id

    redirect_to services_path
  end
end
