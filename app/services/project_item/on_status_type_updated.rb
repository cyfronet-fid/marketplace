# frozen_string_literal: true

class ProjectItem::OnStatusTypeUpdated
  def initialize(project_item)
    @project_item = project_item
  end

  def call
    case @project_item.status_type.to_sym
    when :waiting_for_response
      ProjectItemMailer.waiting_for_response(@project_item).deliver_later if orderable?
    when :approved
      ProjectItemMailer.approved(@project_item).deliver_later if orderable?
    when :ready
      if orderable?
        if !aod?
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
    end
  end

  private

  def orderable?
    offer&.orderable?
  end

  def aod?
    service&.aod?
  end

  def aod_voucherable?
    aod? && offer&.voucherable?
  end

  def offer
    @project_item.offer
  end

  def service
    offer&.service
  end
end
