# frozen_string_literal: true

module Backoffice::ParametersHelper
  def parameter_templates(form)
    content_tag(:div, class: "dropdown") do
      concat content_tag(:button, "Add new parameter",
                         class: "btn btn-success dropdown-toggle", type: "button",
                         "data-toggle": "dropdown", "aria-haspopup": true,
                         "aria-expanded": false, id: "attributes-list-button")
      concat content_tag(:div, parameter_menu_items(form),
                         class: "dropdown-menu",
                         "aria-labelledby": "attributes-list-button")
    end
  end

  def parameter_menu_items(form)
    capture do
      Parameter.all.map do |clazz|
        concat content_tag(:a, I18n.t("properties.#{clazz.type}.add"),
                           class: "dropdown-item",
                           "data-template": parameter_template(clazz.new(id: "js_template_id"), form),
                           "data-action": "click->offer#addAttribute")
      end
    end
  end

  def parameter_template(parameter, form)
    render(partial: "parameters/template",
           locals: { form: form, parameter: parameter }).html_safe
  end
end
