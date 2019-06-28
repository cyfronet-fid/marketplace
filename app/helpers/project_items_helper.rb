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
    (@project_item.ready? && @project_item.service_opinion.nil?)
  end

  def project_item_status(project_item)
    if project_item.in_progress?
      content_tag(:i, nil, class: "fas fa-spinner")
    else
      content_tag(:i, nil, class: "fas fa-circle status-#{project_item.status.dasherize}")
    end
  end
end
