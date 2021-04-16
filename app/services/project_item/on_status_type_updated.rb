# frozen_string_literal: true

class ProjectItem::OnStatusTypeUpdated
  def initialize(project_item)
    @project_item = project_item
  end

  def call
    case @project_item.status_type.to_sym
    when :waiting_for_response
      ProjectItemMailer.waiting_for_response(@project_item).deliver_later if service.orderable?

    when :approved
      ProjectItemMailer.approved(@project_item).deliver_later if service.order_required? && !service.external

    when :ready
      if service.order_required? && !service.external
        if !service.aod?
          ProjectItemMailer.ready_to_use(@project_item).deliver_later
        elsif aod_voucherable?
          ProjectItemMailer.aod_voucher_accepted(@project_item).deliver_later
        else
          ProjectItemMailer.aod_accepted(@project_item).deliver_later
        end
      end

    when :rejected
      if aod_voucherable?
        ProjectItemMailer.aod_voucher_rejected(@project_item).deliver_later
      else
        ProjectItemMailer.rejected(@project_item).deliver_later
      end

    when :closed
      ProjectItemMailer.closed(@project_item).deliver_later

    else
      # nothing to send
    end
  end

  private
    def service
      @project_item.offer.service
    end

    def aod_voucherable?
      service.aod? ? @project_item.voucherable? : false
    end
end
