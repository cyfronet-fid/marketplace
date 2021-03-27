# frozen_string_literal: true

class Jira::IssueUpdated
  def initialize(project_item, changelog)
    @project_item = project_item
    @changelog = changelog || {}
    @jira_client = Jira::Client.new
  end

  def call
    @changelog.fetch("items", []).each do |change|
      status = nil

      if change["field"] == "status"
        case change["to"].to_i
        when @jira_client.wf_rejected_id
          status = :rejected
        when @jira_client.wf_waiting_for_response_id
          status = :waiting_for_response
          ProjectItemMailer.waiting_for_response(@project_item).deliver_later if service.orderable?
        when @jira_client.wf_todo_id
          status = :registered
        when @jira_client.wf_in_progress_id
          status = :in_progress
        when @jira_client.wf_ready_id
          status = :ready
        when @jira_client.wf_closed_id
          status = :closed
          ProjectItemMailer.closed(@project_item).deliver_later
        when @jira_client.wf_approved_id
          status = :approved
          ProjectItemMailer.approved(@project_item).deliver_later if service.order_required? && !service.external
        else
          Rails.logger.warn("Unknown issue status (#{change["to"]}")
        end

        if status
          @project_item.new_status(status: status.to_s, status_type: status)
          if status == :ready && service.order_required? && !service.external
            if service.aod?
              aod_voucherable? ? ProjectItemMailer.aod_voucher_accepted(@project_item).deliver_later :
                  ProjectItemMailer.aod_accepted(@project_item).deliver_later
            else
              ProjectItemMailer.ready_to_use(@project_item).deliver_later
            end
          else
            if status == :rejected
              aod_voucherable? ? ProjectItemMailer.aod_voucher_rejected(@project_item).deliver_later :
                  ProjectItemMailer.rejected(@project_item).deliver_later
            end
          end
        end
      elsif change["field"] == "CP-VoucherID"
        @project_item.new_voucher_change(change["toString"])
      end
    end
  end

  private
    def service
      @service ||= Service.joins(offers: :project_items).
                   find_by(offers: { project_items: @project_item })
    end

    def aod_voucherable?
      service.aod? ? @project_item.voucherable? : false
    end
end
