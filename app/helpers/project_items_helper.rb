# frozen_string_literal: true

module ProjectItemsHelper
  def label_message(message)
    if message.question?
      t("conversations.message.question")
    else
      t("conversations.message.answer")
    end
  end

  def ratingable?
    (@project_item.ready? && @project_item.service_opinion.nil?)
  end

  def webpage(project_item)
    if project_item.external
      project_item.order_url
    else
      project_item.webpage
    end
  end

  def project_item_status(project_item)
    if project_item.in_progress?
      content_tag(:i, nil, class: "fas fa-spinner",
                  "data-toggle": "tooltip", "data-placement": "auto left",
                  "title": "Status: #{t "project_items.status.#{project_item.status_type}"}")
    else
      content_tag(:i, nil, class: "fas fa-circle status-#{project_item.status_type}",
                  "data-toggle": "tooltip", "data-placement": "auto left",
                  "title": "Status: #{t "project_items.status.#{project_item.status_type}"}")
    end
  end

  def service_providers_list(project_item)
    providers = project_item.service.providers.
      map { |p| link_to(p.name, services_path(providers: p)) }
    safe_join(providers, ", ")
  end
end
