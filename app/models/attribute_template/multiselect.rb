# frozen_string_literal: true

class AttributeTemplate::Multiselect < AttributeTemplate
  attr_accessor :values, :min, :max

  def to_attribute
    Attribute::Multiselect.new.tap do |attr|
      attr.id = id
      attr.label = name
      attr.description = hint
      attr.config = {
        # TODO
      }
    end
  end
end

