# frozen_string_literal: true

module ProjectItemsHelper
  def status_change(previous, current)
    if current.question?
      "Your question to service provider"
    elsif previous
      if answer?(previous, current)
        "Service provider message"
      else
        "ProjectItem changed from #{previous.status} to #{current.status}"
      end
    else
      "ProjectItem #{current.status}"
    end
  end

  def answer?(previous, current)
    previous.status == current.status
  end

  def ratingable?
    (@project_item.ready? && project_item_ready?(@project_item) && @project_item.service_opinion.nil?)
  end

  def project_item_ready?(project_item)
    order_change = project_item.order_changes.where(status: :ready).pluck(:created_at)
    order_change.empty? ? false : (order_change.first < RATE_PERIOD)
  end
end
