# frozen_string_literal: true

# You can use this validator in this way in model:
# validates :multiselect_field, multiselect_choices: { collection: my_collection },
class MultiselectChoicesValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return unless options.key?(:collection)
    collection = options[:collection]
    if !value.is_a?(Array) || value.detect { |v| !collection.include?(v) }
      record.errors.add(attribute, "isn't included on the list")
    end
  end
end
