# frozen_string_literal: true

module ProjectItem::Authorize
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!
    before_action :load_and_authorize_project_item!
  end

  private

  def load_and_authorize_project_item!
    @project_item = ProjectItem.joins(:project).find_by(iid: params[:service_id], project_id: params[:project_id])
    @project = @project_item.project

    authorize(@project_item, :show?)
  end
end
