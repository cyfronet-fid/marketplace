# frozen_string_literal: true

module Backoffice::ParametersHelper
  TOOLTIP_TEXT = {
    attribute:
      "The value you provide will be shown as a constant for the user. " +
        "You can use this to describe an unchanging feature of an offer e.g. required access credentials.",
    input: "The user will be prompted to input value, eg. the amount of RAM, storage capacity.",
    select: "The user can choose from the options provided, eg. number of CPU cores, access type.",
    multiselect:
      "The user can choose from the presented options and make multiple selections, eg. authentication option.",
    date: "The user can choose a date, eg. the start or end date of the service availability.",
    range: "The user can choose a value from the provided range, eg. date range, number of CPU hours.",
    quantity_price:
      "The user can select a quantity price, and it will be used to calculate the total price for the entire service."
  }.freeze

  def parameter_templates(form)
    content_tag(:div, class: "parameter-wrapper") do
      concat content_tag(
               :ul,
               parameter_menu_items(form),
               class: "float-left list-group",
               size: 6,
               "aria-labelledby": "attributes-list-button"
             )
      concat content_tag(
               :button,
               content_tag(:i, "", class: "plus-icon"),
               class: "float-right add-button",
               type: "button",
               id: "attributes-list-button",
               disabled: true,
               "data-offer-target": "button",
               "data-action": "click->offer#add"
             )
    end
  end

  def parameter_menu_items(form)
    capture do
      Parameter.all.map do |clazz|
        concat render "parameters/parameters_button",
                      clazz: clazz,
                      form: form,
                      tooltip_text: TOOLTIP_TEXT[clazz.type.parameterize.to_sym],
                      template: parameter_template(clazz.new(id: "js_template_id"), form)
      end
    end
  end

  def parameter_template(parameter, form)
    render(partial: "parameters/template", locals: { form: form, parameter: parameter, index: parameter.id }).html_safe
  end
end
