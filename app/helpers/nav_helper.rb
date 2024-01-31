# frozen_string_literal: true

module NavHelper
  # Navigation link helper
  #
  # Returns an `li` element with an 'active' class if the supplied
  # controller(s) and/or action(s) are currently active. The content of the
  # element is the value passed to the block.
  #
  # options - The options hash used to determine if the element is "active"
  #           (default: {})
  #           :controller   - One or more controller names to check (optional).
  #           :action       - One or more action names to check (optional).
  #           :path         - A shorthand path, such as 'dashboard#index',
  #                           to check (optional).
  #           :active_class - css class name assigned to active elements
  #                           (optional, default: 'active')
  #           :html_options - Extra options to be passed to the list element
  #                           (optional).
  # block   - An optional block that will become the contents of the returned
  #           `li` element.
  #
  # When both :controller and :action are specified, BOTH must match in project_item
  # to be marked as active. When only one is given, either can match.
  #
  # Examples
  #
  #   # Assuming we're on TreeController#show
  #
  #   # Controller matches, but action doesn't
  #   nav_link(controller: [:tree, :refs], action: :edit) { "Hello" }
  #   # => '<li>Hello</li>'
  #
  #   # Controller matches
  #   nav_link(controller: [:tree, :refs]) { "Hello" }
  #   # => '<li class="active">Hello</li>'
  #
  #   # Shorthand path
  #   nav_link(path: 'tree#show') { "Hello" }
  #   # => '<li class="active">Hello</li>'
  #
  #   # Supplying custom options for the list element
  #   nav_link(controller: :tree, html_options: {class: 'home'}) { "Hello" }
  #   # => '<li class="home active">Hello</li>'
  #
  # Returns a list item element String
  def nav_link(options = {}, &)
    o = html_options(options)

    block_given? ? content_tag(:li, capture(&), o) : content_tag(:li, nil, o)
  end

  def active_for_current(options = {})
    clazz = options[:class] || ""
    { class: "#{clazz} #{html_options(options)[:class]}".strip }
  end

  def nav_tab(key, value, options = {}, &)
    active_class = options.fetch(:active_class, "active")
    o = { class: params[key] == value ? " #{active_class}" : "" }

    block_given? ? content_tag(:li, capture(&), o) : content_tag(:li, nil, o)
  end

  private

  def html_options(options)
    klass = extract_klass(options)

    # Add our custom class into the html_options, which may or may not exist
    # and which may or may not already have a :class key
    o = options.delete(:html_options) || {}
    o[:class] ||= ""
    o[:class] += " " + klass
    o[:class].strip!
    o
  end

  def extract_klass(options)
    act, ctrl = extract_controller_and_action(options)
    active_class = options.fetch(:active_class, "active")
    if ctrl && act
      # When given both options, make sure BOTH are active
      current_controller_and_action?(act, ctrl) ? active_class : ""
    else
      # Otherwise check EITHER option
      current_controller_or_action(act, ctrl) ? active_class : ""
    end
  end

  def current_controller_or_action(act, ctrl)
    current_controller?(*ctrl) || current_action?(*act)
  end

  def current_controller_and_action?(act, ctrl)
    current_controller?(*ctrl) && current_action?(*act)
  end

  def extract_controller_and_action(options)
    path = options.delete(:path)
    if path
      act, ctrl = extract_ctrl_and_action_from_path(path)
    else
      ctrl = options.delete(:controller)
      act = options.delete(:action)
    end
    [act, ctrl]
  end

  def extract_ctrl_and_action_from_path(path)
    if path.respond_to?(:each)
      ctrl = path.map { |p| p.split("#").first }
      act = path.map { |p| p.split("#").last }
    else
      ctrl, act, = path.split("#")
    end
    [act, ctrl]
  end

  def show_administrative_sections?
    policy(%i[backoffice backoffice]).show? || policy(%i[admin admin]).show? || policy(%i[executive executive]).show?
  end
end
