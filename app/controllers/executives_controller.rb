# frozen_string_literal: true

class ExecutivesController < Executive::ApplicationController
  def show
    redirect_to executive_statistics_path
  end
end
