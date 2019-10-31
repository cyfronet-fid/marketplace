# frozen_string_literal: true

class ProjectItem::Create
  def initialize(project_item)
    @project_item = project_item
  end

  def call
    @project_item.created!

    if @project_item.save
      @project_item.statuses.create(status: :created,
                               message: "Service request created")

      unless normal?
        ProjectItem::ReadyJob.perform_later(@project_item)
      else
        ProjectItemMailer.created(@project_item).deliver_later
        ProjectItem::RegisterJob.perform_later(@project_item)
      end
    end

    @project_item
  end

  private

    def normal?
      @project_item.offer.normal?
    end
end
