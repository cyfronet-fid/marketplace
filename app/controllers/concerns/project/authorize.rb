# frozen_string_literal: true

module Project::Authorize
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!
    before_action :load_and_authorize_project!
  end

  private

  def load_and_authorize_project!
    @project = Project.find_by_id(params[:project_id])
    authorize(@project, :show?)
  end
end
