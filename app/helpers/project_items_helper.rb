# frozen_string_literal: true

module ProjectItemsHelper
  def status_change(previous, current)
    if current.question?
      "Your question to service provider"
    elsif previous
      if answer?(previous, current)
        "Service provider message"
      else
        "Status changed from #{previous.status} to #{current.status}"
      end
    else
      "Service request #{current.status}"
    end
  end

  def answer?(previous, current)
    previous.status == current.status
  end

  def ratingable?
    (@project_item.ready? && project_item_ready?(@project_item) && @project_item.service_opinion.nil?)
  end

  def project_item_ready?(project_item)
    project_item_change = project_item.project_item_changes.where(status: :ready).pluck(:created_at)
    project_item_change.empty? ? false : (project_item_change.first < RATE_AFTER_PERIOD.ago)
  end
end
