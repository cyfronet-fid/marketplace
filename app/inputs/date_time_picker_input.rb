# frozen_string_literal: true

class DateTimePickerInput < SimpleForm::Inputs::Base
  def input(wrapper_options = nil)
    merged_input_options = merge_wrapper_options(input_html_options, wrapper_options)
    @builder.text_field(attribute_name, custom_input_options(merged_input_options))
  end

  def custom_input_options(merged_input_options)
    merge_wrapper_options(
      merged_input_options,
      class: "form-control",
      readonly: true,
      "data-provide": "datepicker",
      "data-date-autoclose": "true"
    )
  end
end
