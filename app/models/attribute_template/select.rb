# frozen_string_literal: true

class AttributeTemplate::Select < AttributeTemplate
  attr_accessor :values

  def to_attribute
    Attribute::Select.new.tap do |attr|
      attr.id = id
      attr.label = name
      attr.description = hint
    end
  end
end
