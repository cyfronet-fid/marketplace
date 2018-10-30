# frozen_string_literal: true

class ProjectItem::Ready
  class JIRAIssueCreateError < StandardError
    def initialize(project_item, msg = "")
      super(msg)
      @project_item = project_item
    end
  end

  class JIRATransitionSaveError < StandardError
    def initialize(project_item, msg = "")
      super(msg)
      @project_item = project_item
    end
  end

  def initialize(project_item)
    @project_item = project_item
  end


  def call
    ready_in_jira! &&
    update_status! &&
    notify!
  end

  private
    def ready_in_jira!
      client = Jira::Client.new
      issue = client.Issue.build

      if issue.save(fields: { summary: "Add open service #{@project_item.service.title}",
                    project: { key: client.jira_project_key },
                    issuetype: { id: client.jira_issue_type_id } })

        trs = issue.transitions.all.select { |tr| tr.name == "Done" }
        if trs.length > 0
          transition = issue.transitions.build
          transition.save!("transition" => { "id" => trs.first.id })
          @project_item.update_attributes(issue_id: issue.id, issue_status: :jira_active)
        else
          raise JIRATransitionSaveError.new(@project_item)
        end

      else
        @project_item.jira_errored!
        raise JIRAIssueCreateError.new(@project_item)
      end
    end

    def update_status!
      @project_item.new_change(status: :ready,
                               message: activate_message)
    end

    def activate_message
      service.activate_message || "Your service request is ready"
    end

    def notify!
      ProjectItemMailer.changed(@project_item).deliver_later
      ProjectItemMailer.rate_service(@project_item).deliver_later(wait_until: RATE_AFTER_PERIOD.from_now)
    end

    def service
      @service ||= Service.joins(offers: :project_items).
                   find_by(offers: { project_items: @project_item })
    end
end
