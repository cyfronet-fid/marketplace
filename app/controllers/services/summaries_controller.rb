# frozen_string_literal: true

class Services::SummariesController < Services::ApplicationController
  before_action :ensure_in_session!

  def show
    @project_item = ProjectItem.new(session[session_key])
  end

  def create
    project_item_template = ProjectItem.new(session[session_key])
    authorize(project_item_template)

    @project_item = ProjectItem::Create.new(project_item_template).call

    if @project_item.persisted?
      render :confirmation, layout: "ordered"
    else
      redirect_to service_configuration_path(@service),
                  alert: "Service request configuration invalid"
    end
  end
end
