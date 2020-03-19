# frozen_string_literal: true

class AttributeTemplate::Input < AttributeTemplate
  attr_accessor :unit

  def to_attribute
    Attribute::Input.new.tap do |attr|
      attr.id = id
      attr.label = name
      attr.description = hint
      attr.unit = unit
    end
  end
end
