# frozen_string_literal: true

class AttributesInput < SimpleForm::Inputs::TextInput
  def input(wrapper_options)
    input_html_options[:type] ||= input_type

    merged_input_options = merge_wrapper_options(input_html_options, wrapper_options)

    existing_value =
      Array(object.public_send(attribute_name)).map.with_index do |array_el, index|
        merged_options =
          merged_input_options.merge(
            value: array_el,
            name: "#{object_name}[#{attribute_name}][]",
            id: "#{object_name}_#{attribute_name}_#{index}",
            class: "form-control "
          )

        if input_has_errors?(index)
          error = @builder.full_error("#{attribute_name}_#{index}", class: "invalid-feedback d-block")
          merged_options = merged_options.merge(class: "is-invalid form-control text")
        end

        input = @builder.text_area(nil, merged_options)
        input + error
      end

    unless object.errors.present?
      number = Array(object.public_send(attribute_name)).length
      existing_value.push @builder.text_area(
                            nil,
                            merged_input_options.merge(
                              value: nil,
                              name: "#{object_name}[#{attribute_name}][]",
                              id: "#{object_name}_#{attribute_name}_#{number}",
                              class: "form-control text"
                            )
                          )
    end
    existing_value.join.html_safe
  end

  def input_has_errors?(index)
    object.errors["#{attribute_name}_#{index}"].present?
  end

  def input_type
    :text
  end
end
