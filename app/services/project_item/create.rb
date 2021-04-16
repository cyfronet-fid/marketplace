# frozen_string_literal: true

class ProjectItem::Create
  def initialize(project_item, message = nil)
    @project_item = project_item
    @message = message
  end

  def call
    if @project_item.update(status: "created", status_type: :created)
      if orderable?
        ProjectItem::RegisterJob.perform_later(@project_item, @message)
        ProjectItemMailer.created(@project_item).deliver_later
      else
        ProjectItem::ReadyJob.perform_later(@project_item, @message)
        ProjectItemMailer.added_to_project(@project_item).deliver_later
      end
    end

    @project_item
  end

  private
    def orderable?
      @project_item.offer.orderable?
    end
end
