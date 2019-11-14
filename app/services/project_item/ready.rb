# frozen_string_literal: true

class ProjectItem::Ready
  class JIRATransitionSaveError < StandardError
    def initialize(project_item, msg = "")
      super(msg)
      @project_item = project_item
    end
  end

  def initialize(project_item, message = nil)
    @project_item = project_item
    @message = message
  end


  def call
    ready_in_jira! &&
    update_status! &&
    create_message &&
    notify!
  end

  private
    def ready_in_jira!
      client = Jira::Client.new
      begin
        unless @project_item.project.jira_active?
          Project::Register.new(@project_item.project).call
        end

        issue = client.create_service_issue(@project_item)

        trs = issue.transitions.all.select { |tr| tr.to.id.to_i == client.wf_ready_id }

        if trs.length > 0
          transition = issue.transitions.build
          transition.save!("transition" => { "id" => trs.first.id })
          @project_item.update_attributes(issue_id: issue.id, issue_status: :jira_active)
          @project_item.save
        else
          @project_item.update_attributes(issue_id: issue.id)
          @project_item.jira_errored!
          raise JIRATransitionSaveError.new(@project_item)
        end
      rescue Jira::Client::JIRAIssueCreateError => e
        @project_item.jira_errored!
        raise e
      end
    end

    def update_status!
      @project_item.new_status(status: :ready,
                               message: activate_message)
    end

    def activate_message
      service.activate_message || "Your service request is ready"
    end

    def notify!
      ProjectItemMailer.status_changed(@project_item).deliver_later if @project_item.orderable?
      ProjectItemMailer.rate_service(@project_item).deliver_later(wait_until: RATE_AFTER_PERIOD.from_now)
    end

    def service
      @service ||= Service.joins(offers: :project_items).
                   find_by(offers: { project_items: @project_item })
    end

    def create_message
      if @message
        message_temp = Message.new(author: @project_item.user,
                                   message: @message,
                                   messageable: @project_item)
        Message::Create.new(message_temp).call
      end
      true
    end
end
