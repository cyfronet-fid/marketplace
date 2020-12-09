# frozen_string_literal: true

module FormsHelper
  def link_to_add_array_field(model, field_name)
    content_tag(:a, "Add new " + t("simple_form.add_new_array_item.#{model}.#{field_name}"),
                class: "btn btn-sm btn-primary disablable",
                data:  {
                    action: "click->service#addNewArrayField",
                    wrapper: "#{model}_#{field_name}",
                    name: "#{model}[#{field_name}][]",
                    class: "form-control text optional" })
  end
end
