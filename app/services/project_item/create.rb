# frozen_string_literal: true

class ProjectItem::Create
  def initialize(project_item)
    @project_item = project_item
  end

  def call
    @project_item.created!

    if @project_item.save
      @project_item.new_change(status: :created,
                               message: "Service request created")

      if open_access?
        ProjectItem::ReadyJob.perform_later(@project_item)
      else
        ProjectItemMailer.created(@project_item).deliver_later
        ProjectItem::RegisterJob.perform_later(@project_item)
      end
    end

    @project_item
  end

  private

    def open_access?
      Service.joins(:offers).
        find_by(offers: { id: @project_item.offer_id })&.
        open_access?
    end
end
