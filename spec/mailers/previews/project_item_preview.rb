# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/project_item
#
# !!! We are using last created project_item to show email previews !!!
class ProjectItemPreview < ActionMailer::Preview
  def created
    ProjectItemMailer.created(ProjectItem.last)
  end

  def status_changed
    ProjectItemMailer.status_changed(ProjectItem.last)
  end

  def new_message
    ProjectItemMailer.new_message(ProjectItem.last)
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
