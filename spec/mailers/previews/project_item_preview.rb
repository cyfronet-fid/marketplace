# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/project_item
#
# !!! We are using last created project_item to show email previews !!!
class ProjectItemPreview < ActionMailer::Preview
  def created
    ProjectItemMailer.created(ProjectItem.last)
  end

  def changed
    ProjectItemMailer.changed(ProjectItem.last)
  end

  def new_message
    ProjectItemMailer.new_message(ProjectItem.last)
  end
end
