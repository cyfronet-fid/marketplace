# frozen_string_literal: true

module ProjectItem::Attributes
  extend ActiveSupport::Concern

  included do
    attribute :property_values
    attribute :offers_property_values

    validates_associated :property_values
    before_save :map_properties
  end


  def property_values
    if !@property_values
      if properties.nil?
        @property_values = offer.attributes.dup
      else
        @property_values = properties.map { |prop| Attribute.from_json(prop) }
      end
    end
    @property_values
  end

  def property_values=(property_values)
    if property_values.is_a?(Array)
      @property_values = property_values
    elsif property_values.is_a?(Hash)
      props = []
      property_values.each { |id, value|
        attr = offer.attributes.find { |a| id == a.id }.dup
        attr.value_from_param(value)
        props << attr
      }
      @property_values = props
    end
    self.write_attribute(:property_values, @property_values)
    @property_values
  end

  private

    def property_values_for(offer)
    end

    def map_properties
      self.properties = property_values.map(&:to_json)
    end
end
