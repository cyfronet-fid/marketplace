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
    links.push({ href: admin_path, caption: _("Admin") }) if policy(%i[admin admin]).show?
    links.to_json
  end

  def meta_og_title_content
    ENV.fetch(
      "MP_META_TITLE",
      "I've come across the interesting EOSC resource. Please have a look when you get a chance!"
    )
  end

  def meta_og_description_content
    ENV.fetch(
      "MP_META_DESCRIPTION",
      "This scientific record comes from the EOSC Catalogue & Marketplace,
    a platform where you can browse, save, and order a wide variety of scientific resources.
    You can choose from publications, data, software, services, data sources, training materials and other.
    Explore this huge European database of science."
    )
  end
  def external_search_url(include_query: false)
    if Rails.configuration.enable_external_search && Rails.configuration.search_service_base_url.present?
      query = ""
      if include_query
        category = request.query_parameters["return_path"] || "search/all"
        search_params = CGI.unescape(request.query_parameters["search_params"] || "")
        query = "/#{category}?#{search_params}"
      end

      Rails.configuration.search_service_base_url + query
    end
  end

  def whitelabel
    Rails.configuration.whitelabel
  end

  def render_turbo_stream_flash
    turbo_stream.prepend "flash-messages", partial: "layouts/flash"
  end

  def recaptcha_tags(options = {})
    return unless Rails.application.config.recaptcha_enabled
    super
  end
end
