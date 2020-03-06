# frozen_string_literal: true

module Backoffice::AttributesHelper
  def attribute_templates(form)
    content_tag(:div, class: "dropdown") do
      concat content_tag(:button, "Add new parameter",
                         class: "btn btn-success dropdown-toggle", type: "button",
                         "data-toggle": "dropdown", "aria-haspopup": true,
                         "aria-expanded": false, id: "attributes-list-button")
      concat content_tag(:div, attributes_menu_items(form),
                         class: "dropdown-menu",
                         "aria-labelledby": "attributes-list-button")
    end
  end

  def attributes_menu_items(form)
    capture do
      attributes.map do |clazz|
        concat content_tag(:a, I18n.t("attributes.template.#{clazz::TYPE.underscore}.add"),
                           class: "dropdown-item",
                           "data-template": attribute_template(clazz.new(id: "js_template_id"), form),
                           "data-action": "click->offer#addAttribute")
      end
    end
  end

  def attribute_template(attr, form)
    render(partial: "attributes/template",
           locals: { form: form, attribute: attr }).html_safe
  end

  def attributes
    [Attribute::Input, Attribute::Select,
     Attribute::Multiselect, Attribute::Date,
     Attribute::Range, Attribute::QuantityPrice]
  end
end
