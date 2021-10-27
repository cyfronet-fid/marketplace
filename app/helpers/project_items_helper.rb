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

  def voucher_id(project_item)
    project_item.user_secrets["voucher_id"] || project_item.voucher_id
  end

  def webpage(project_item)
    project_item.order_url.presence || project_item.service.webpage_url
  end

  def project_item_status(project_item)
    if project_item.in_progress?
      content_tag(:i, nil, class: "fas fa-spinner",
                           "data-toggle": "tooltip", "data-placement": "auto left",
                           title: "Status: #{t "project_items.status.#{project_item.status_type}"}")
    else
      content_tag(:i, nil, class: "fas fa-circle status-#{project_item.status_type}",
                           "data-toggle": "tooltip", "data-placement": "auto left",
                           title: "Status: #{t "project_items.status.#{project_item.status_type}"}")
    end
  end

  def service_resource_organisation(project_item)
    organisation = project_item.service.resource_organisation
    link_to organisation.name, services_path(providers: organisation.id)
  end

  def service_providers_list(project_item)
    organisation = project_item.service.resource_organisation
    providers = project_item.service.providers.reject { |p| p == organisation }
                            .map { |p| link_to(p.name, services_path(providers: p.id)) }
    safe_join(providers, ", ")
  end
end
