# frozen_string_literal: true

class AttributeTemplate::Date < AttributeTemplate
  attr_accessor :min, :max

  def to_attribute
    Attribute::Date.new.tap do |attr|
      attr.id = id
      attr.label = name
      attr.description = hint
    end
  end
end
