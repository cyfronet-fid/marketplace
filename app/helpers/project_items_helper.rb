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
end
