# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/project_item
#
# !!! We are using last created project_item to show email previews !!!
class WebhookJiraPreview < ActionMailer::Preview
  def new_message_for_project_item
    WebhookJiraMailer.new_message(Message.new(messageable: ProjectItem.last, message: "message content"))
  end


  def project_new_message
    WebhookJiraMailer.new_message(Message.new(messageable: Project.last, message: "message content"))
  end
end
