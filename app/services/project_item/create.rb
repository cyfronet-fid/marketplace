# frozen_string_literal: true

class ProjectItem::Create
  def initialize(project_item)
    @project_item = project_item
  end

  def call
    @project_item.created!
    @service = Service.find_by(id: @project_item.service_id)

    if @project_item.save
      @project_item.new_change(status: :created, message: "ProjectItem created")
      ProjectItemMailer.created(@project_item).deliver_later

      if !@service.open_access
        ProjectItem::RegisterJob.perform_later(@project_item)
      else
        ProjectItem::ReadyJob.perform_later(@project_item)
      end
    end

    @project_item
  end
end
