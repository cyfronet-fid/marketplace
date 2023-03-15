# frozen_string_literal: true

module FormsHelper
  def link_to_add_array_field(model, field_name)
    content_tag(
      :a,
      "Add new " + t("simple_form.add_new_array_item.#{model}.#{field_name}"),
      class: "btn btn-sm btn-primary disablable",
      data: {
        action: "click->form#addNewArrayField",
        wrapper: "#{model}_#{field_name}",
        name: "#{model}[#{field_name}][]",
        class: "form-control text optional"
      }
    )
  end

  def snake_cased(model_name)
    model_name.parameterize(separator: "_")
  end

  def checkbox_class(option, values)
    enabled = values.include?(option[:id].to_s)
    state = enabled ? "checked" : "unchecked"
    if values && option[:children]
      if (option[:children]&.map { |c| c[:id].to_s } & values).size.between?(1, option[:children].size - 1)
        "indeterminate"
      else
        state
      end
    end
  end

  def contact_form_message
    message =
      "  Accept EOSC Helpdesk <a target=\"_blank\" href=\"https://eosc-helpdesk.scc.kit.edu/privacy-policy\">" +
        "Data Privacy Policy</a> & <a target=\"_blank\" " +
        "href=\"https://eosc-helpdesk.scc.kit.edu/aup\">Acceptable Use Policy</a>"
    message.html_safe
  end
end
