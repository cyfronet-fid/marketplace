# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/project_item
#
# !!! We are using last created project_item to show email previews !!!
class ProjectItemPreview < ActionMailer::Preview
  def created
    ProjectItemMailer.created(ProjectItem.last)
  end

  def waiting_for_response
    ProjectItemMailer.waiting_for_response(ProjectItem.last)
  end

  def added_to_project
    ProjectItemMailer.added_to_project(ProjectItem.last)
  end

  def approved
    ProjectItemMailer.approved(ProjectItem.last)
  end

  def ready_to_use
    ProjectItemMailer.ready_to_use(ProjectItem.last)
  end

  def rejected
    ProjectItemMailer.rejected(ProjectItem.last)
  end

  def closed
    ProjectItemMailer.closed(ProjectItem.last)
  end

  def aod_voucher_accepted
    ProjectItemMailer.aod_voucher_accepted(ProjectItem.last)
  end

  def aod_accepted
    ProjectItemMailer.aod_accepted(ProjectItem.last)
  end

  def aod_voucher_rejected
    ProjectItemMailer.aod_voucher_rejected(ProjectItem.last)
  end
end
