# frozen_string_literal: true

class ProjectItem::Register
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

      begin
        unless @project_item.project.jira_active?
          Project::Register.new(@project_item.project).call
        end

        issue = client.create_service_issue(@project_item)
        @project_item.update_attributes(issue_id: issue.id, issue_status: :jira_active)
        @project_item.save
        true
      rescue Jira::Client::JIRAIssueCreateError => e
        @project_item.jira_errored!
        raise e
      end
    end

    def update_status!
      @project_item.new_status(status: :registered,
                        message: "Your service request was registered in the order handling system")
      true
    end

    def notify!
      ProjectItemMailer.status_changed(@project_item).deliver_later
    end

    def encode_properties(property_values)
      property_values.map { |property| "#{property.label}=#{property.value}" }.join("&")
    end
end
