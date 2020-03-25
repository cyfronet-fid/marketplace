# frozen_string_literal: true

module Backoffice::ParametersHelper
  def parameter_templates(form)
    content_tag(:div, class: "parameter-wrapper") do
      concat content_tag(:ul, parameter_menu_items(form),
                         class: "float-left list-group", size: 6,
                         "aria-labelledby": "attributes-list-button")
      concat content_tag(:button, content_tag(:i, "", class: "fas fa-chevron-right"),
                         class: "float-right add-button", type: "button",
                         id: "attributes-list-button",
                         "disabled": true,
                         "data-target": "offer.button",
                         "data-action": "click->offer#add")
      concat content_tag(:span)
    end
  end

  def parameter_menu_items(form)
    capture do
      Parameter.all.map do |clazz|
        concat content_tag(:li, I18n.t("parameters.#{clazz.type}.add"),
                           class: "list-group-item",
                           "data-template": parameter_template(clazz.new(id: "js_template_id"), form),
                           "data-action": "click->offer#selectParameterType")
      end
    end
  end

  def parameter_template(parameter, form)
    render(partial: "parameters/template",
           locals: { form: form, parameter: parameter }).html_safe
  end
end
