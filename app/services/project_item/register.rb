# frozen_string_literal: true

class ProjectItem::Register
  class JIRAIssueCreateError < StandardError
    def initialize(project_item, msg = "")
      super(msg)
      @project_item = project_item
    end
  end

  def initialize(project_item)
    @project_item = project_item
  end

  def call
    register_in_jira! &&
    update_status! &&
    notify!
  end

  private

    def register_in_jira!
      client = Jira::Client.new
      @project_item.save

      if (issue = client.create_service_issue(@project_item))
        @project_item.update_attributes(issue_id: issue.id, issue_status: :jira_active)
        @project_item.save
        true
      else
        @project_item.jira_errored!
        raise JIRAIssueCreateError.new(@project_item)
      end
    end

    def update_status!
      @project_item.new_change(status: :registered,
                        message: "Your service request was registered in the order handling system")
      true
    end

    def notify!
      ProjectItemMailer.changed(@project_item).deliver_later
    end

    def encode_properties(property_values)
      property_values.map { |property| "#{property.label}=#{property.value}" }.join("&")
    end
end
