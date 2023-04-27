# frozen_string_literal: true

module ApplicationHelper
  include Pagy::Frontend

  # Check if a particular controller is the current one
  #
  # args - One or more controller names to check
  #
  # Examples
  #
  #   # On TreeController
  #   current_controller?(:tree)           # => true
  #   current_controller?(:commits)        # => false
  #   current_controller?(:commits, :tree) # => true
  def current_controller?(*args)
    args.any? { |v| v.to_s.downcase == controller.controller_name }
  end

  # Check if a partcular action is the current one
  #
  # args - One or more action names to check
  #
  # Examples
  #
  #   # On Projects#new
  #   current_action?(:new)           # => true
  #   current_action?(:create)        # => false
  #   current_action?(:new, :create)  # => true
  def current_action?(*args)
    args.any? { |v| v.to_s.downcase == action_name }
  end

  def back_link_to(title, record, options = {})
    prefix = options.delete(:prefix)
    to_obj = record.persisted? ? record : record.class
    to = prefix ? [prefix, to_obj] : to_obj
    link_to(title, to, options)
  end

  def meta_robots
    if ENV["MP_INSTANCE"].present? || Rails.env.development?
      "<meta name=\"robots\" content=\"noindex, nofollow\">".html_safe
    else
      "<meta name=\"robots\" content=\"index, follow\">".html_safe
    end
  end

  def yield_content!(content_key)
    view_flow.content.delete(content_key)
  end

  def placeholder(variant, text = "Placeholder - link to about", link = about_path)
    render "layouts/placeholder", text: text, link: link, variant: variant
  end

  def eosc_commons_profile_links
    links = []

    # if show_administrative_sections?
    #   .border-top
    if policy(%i[backoffice backoffice]).show?
      links.push({ href: backoffice_path, caption: _("Backoffice"), "data-e2e": "backoffice" })
    end
    if policy(%i[admin admin]).show?
      links.push({ href: admin_path, caption: _("Admin") })
      links.push({ href: executive_path, caption: _("Executive") }) if policy(%i[executive executive]).show?
    end
    links.to_json
  end

  def external_search_url(include_query: false)
    if Rails.configuration.enable_external_search && Rails.configuration.search_service_base_url.present?
      query = ""
      if include_query
        category = request.query_parameters["pv"] || "search/all"
        q = request.query_parameters["q"] || "*"
        query = "/#{category}?q=#{q}"
      end

      Rails.configuration.search_service_base_url + query
    end
  end

  def whitelabel
    Rails.configuration.whitelabel
  end
end
