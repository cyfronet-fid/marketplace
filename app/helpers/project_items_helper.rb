# frozen_string_literal: true

module ProjectItemsHelper
  def label_message(message)
    date = message.created_at.to_fs(:db)

    case message.author_role
    when "user"
      "#{_("You")}, #{date}"
    when "provider"
      "#{date}#{author_identity(message)}, #{_("Provider")}"
    else
      # mediator
      "#{date}#{author_identity(message)}, #{_("Customer service")}"
    end
  end

  def author_identity(message)
    if message.author_name.present? && message.author_email.present?
      ", #{message.author_name} (#{message.author_email})"
    elsif message.author_name.present? && message.author_email.blank?
      ", #{message.author_name}"
    elsif message.author_name.blank? && message.author_email.present?
      ", #{message.author_email}"
    end
  end

  def ratingable?
    @project_item.ready? && @project_item.service_opinion.nil?
  end

  def voucher_id(project_item)
    project_item.user_secrets["voucher_id"] || project_item.voucher_id
  end

  def webpage(project_item)
    project_item.order_url.blank? ? project_item.service.webpage_url : project_item.order_url
  end

  def project_item_status(project_item)
    if project_item.in_progress?
      content_tag(:div, t("project_items.status.#{project_item.status_type}"), class: "status-box status-bg-progress")
    else
      content_tag(
        :div,
        t("project_items.status.#{project_item.status_type}"),
        class: "status-box status-bg-#{project_item.status_type}"
      )
    end
  end

  def archive_project_prompt
    _("Are you sure you want to archive this project? It won't be possible to use it anymore")
  end
end
