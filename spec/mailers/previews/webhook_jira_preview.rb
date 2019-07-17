# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/project_item
#
# !!! We are using last created project_item to show email previews !!!
class WebhookJiraPreview < ActionMailer::Preview
  def new_message_for_project_item
    WebhookJiraMailer.new_message(ProjectItem.last)
  end

  def new_message_for_project
    WebhookJiraMailer.new_message(Project.last)
  end
end
