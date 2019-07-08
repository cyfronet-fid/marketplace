# frozen_string_literal: true

module ProjectItemsHelper
  def label_message(previous, current)
    if current.is_a?(Message)
      if current.question?
        t("#{controller_name}.message.question")
      else
        t("#{controller_name}.message.answer")
      end
    elsif previous && previous.is_a?(Status) && !answer?(previous, current)
      "Status changed from #{previous.status} to #{current.status}"
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
      content_tag(:i, nil, class: "fas fa-circle status-#{project_item.status}")
    end
  end
end
