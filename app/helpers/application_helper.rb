# frozen_string_literal: true

module ApplicationHelper
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
      '<meta name="robots" content="noindex, nofollow">'.html_safe
    else
      '<meta name="robots" content="index, follow">'.html_safe
    end
  end

  def yield_content!(content_key)
    view_flow.content.delete(content_key)
  end
end
