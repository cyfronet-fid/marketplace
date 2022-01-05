# frozen_string_literal: true

class ProjectItem::Register
  def initialize(project_item, message = nil)
    @project_item = project_item
    @message = message

    if @project_item.class != ProjectItem
      raise ArgumentError, "project_item must be exactly ProjectItem, not its subclass: received #{@project_item.class}"
    end
  end

  def call
    register_in_jira! && update_status! && create_message
  end

  private

  def register_in_jira!
    client = Jira::Client.new
    @project_item.save!

    begin
      Project::Register.new(@project_item.project).call unless @project_item.project.jira_active?

      issue = client.create_service_issue(@project_item)
      @project_item.update!(issue_id: issue.id, issue_status: :jira_active)
      @project_item.save!
    rescue Jira::Client::JIRAIssueCreateError => e
      @project_item.jira_errored!
      raise e
    end
  end

  def update_status!
    @project_item.new_status!(status: "registered", status_type: :registered)
    true
  end

  def encode_properties(property_values)
    property_values.map { |property| "#{property.label}=#{property.value}" }.join("&")
  end

  def create_message
    if @message
      message_temp =
        Message.new(
          author: @project_item.user,
          author_role: :user,
          scope: :public,
          message: @message,
          messageable: @project_item
        )
      Message::Create.new(message_temp).call
    end
    true
  end
end
