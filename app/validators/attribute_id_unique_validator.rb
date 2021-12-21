# frozen_string_literal: true

class AttributeIdUniqueValidator < ActiveModel::EachValidator
  def validate_each(record, _attribute, _value)
    return unless record.errors.blank?

    arry = (record.parameters_as_string || []).map { |p| JSON.parse(p)["id"] }
    arry.each_with_index do |e, i|
      record.errors.add("parameters_as_string_#{i}", "Id must be unique") if arry.count(e) > 1
    end
  end
end
