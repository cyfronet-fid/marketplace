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
      message = "Status changed"

      if change["field"] == "status"
        case change["to"].to_i
        when @jira_client.wf_rejected_id
          status = :rejected
        when @jira_client.wf_waiting_for_response_id
          status = :waiting_for_response
        when @jira_client.wf_todo_id
          status = :registered
        when @jira_client.wf_in_progress_id
          status = :in_progress
        when @jira_client.wf_done_id
          status = :ready
          message = service.activate_message || "Service is ready to be used"
        else
          Rails.logger.warn("Unknown issue status (#{change["to"]}")
        end

        if status
          @project_item.new_change(status: status, message: message)
          if status == :ready
            if aod_voucherable?
              ProjectItemMailer.aod_voucher_accepted(@project_item).deliver_later
            else
              ProjectItemMailer.aod_accepted(@project_item).deliver_later
            end
          else
            if aod_voucherable? && status == :rejected
              ProjectItemMailer.aod_voucher_rejected(@project_item).deliver_later
            else
              ProjectItemMailer.changed(@project_item).deliver_later
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
      service.aod? ? @project_item.vaucherable? : false
    end
end
