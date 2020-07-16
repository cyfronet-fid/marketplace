# frozen_string_literal: true

class ArrayInput < SimpleForm::Inputs::TextInput
  def input(wrapper_options)
    input_html_options[:type] ||= input_type
    existing_value = Array(object.public_send(attribute_name)).map.with_index do |array_el, index|
      @builder.text_area(nil, input_html_options.merge(value: array_el,
                                                        name: "#{object_name}[#{attribute_name}][]",
                                                        id: "#{object_name}_#{attribute_name}_#{index}"))
    end
    number = Array(object.public_send(attribute_name)).length
    existing_value.push @builder.text_area(nil,
                                             input_html_options.merge(value: nil,
                                                                      name: "#{object_name}[#{attribute_name}][]",
                                                                      id: "#{object_name}_#{attribute_name}_#{number}"))
    existing_value.join.html_safe
  end

  def input_type
    :text
  end
end
