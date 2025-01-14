# frozen_string_literal: true
class CustomInput < SimpleForm::Inputs::StringInput
  def input(wrapper_options = nil)
    merged_input_options = merge_wrapper_options(input_html_options, wrapper_options)
    template.text_field_tag(attribute_name, nil, merged_input_options)
  end
end
