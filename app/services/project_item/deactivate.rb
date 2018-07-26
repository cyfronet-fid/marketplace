# frozen_string_literal: true

class ProjectItem::Deactivate
  def initialize(project_item)
    @project_item = project_item
  end

  def call
    if !(@project_item.deactivated? || @project_item.rejected?)
      update_project_item_status! &&
      notify!
    end
  end

  private

    def update_project_item_status!
      @project_item.new_change(status: :deactivated,
                               message: "This service is not active anymore. You can activate it at any time from the service entry page")
    end

    def notify!
      ProjectItemMailer.changed(@project_item).deliver_later
    end
end
