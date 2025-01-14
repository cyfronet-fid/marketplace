# frozen_string_literal: true

class Attribute
  extend ActiveModel::Naming
  include ActiveModel::Conversion
  include ActiveModel::Validations

  attr_accessor :id, :label, :description, :value_type, :unit, :config, :value
  attr_writer :type

  validate :value_validity

  def persisted?
    false
  end

  def value_validity
    unless value_valid?
      # this needs to be like that - simple form is based on the f.input :id
      errors.add(:id, "Invalid attribute value")
    end
    # TODO: add more speciffic errors under type speciffic fieds eg. :min, :max, and handle them in views
    # examples
    # errors.add(:min, "Minimum value not met")
  end

  def parameter?
    !config.nil?
  end

  def property?
    !value.nil?
  end

  def config_valid?
    JSON::Validator.validate(config_schema, config)
  end

  def value_valid?
    JSON::Validator.validate(value_schema, value, parse_data: false)
  end

  def validate_config!
    JSON::Validator.validate!(config_schema, config)
  end

  def validate_value!
    JSON::Validator.validate!(value_schema, value)
  end

  def validate_value_type!
    JSON::Validator.validate!(value_type_schema, @value_type)
  end

  def type
    self.class::TYPE
  end

  def to_json(*_args)
    json = {}
    json["id"] = id
    json["label"] = label
    json["type"] = type
    json["value_type"] = value_type
    json["unit"] = unit unless unit.nil?
    json["value"] = value unless value.nil?
    json["config"] = config unless config.nil?
    json["description"] = description unless description.nil?
    json
  end

  def value_from_param(param)
    unless param.blank?
      case value_type
      when "integer"
        @value =
          begin
            Integer(param)
          rescue StandardError
            String(param)
          end
      when "string"
        @value = String(param)
      else
        @value = param
      end
    end
  end

  def value_type_schema
    # overload to reflect support for other types for attribute
    { type: "string", enum: %w[string integer] }
  end

  def value_schema
    # overload this method to create other schemas for values
    { type: value_type }
  end

  def config_schema
    # you need to overload this to create attribute types
    # by default attribute is property without any configuration
    { type: "null" }
  end

  def self.from_json(json, validate: true)
    JSON::Validator.validate!(ATTRIBUTE_SCHEMA, json)

    case json["type"]
    when "input"
      attr = Attribute::Input.new
    when "select"
      attr = Attribute::Select.new
    when "multiselect"
      attr = Attribute::Multiselect.new
    when "range"
      attr = Attribute::Range.new
    when "date"
      attr = Attribute::Date.new
    when "range-property"
      attr = Attribute::RangeProperty.new
    when "quantity_price"
      attr = Attribute::QuantityPrice.new
    else
      attr = Attribute.new
    end
    attr.id = json["id"]
    attr.label = json["label"]
    attr.value_type = json["value_type"]
    attr.unit = json["unit"]
    attr.config = json["config"]
    attr.description = json["description"]
    attr.value = json["value"] unless json["value"].blank?
    attr.validate_value_type! if validate
    attr
  end

  ATTRIBUTE_SCHEMA = {
    type: "object",
    required: %w[id label type value_type],
    properties: {
      id: {
        type: "string"
      },
      label: {
        type: "string"
      },
      description: {
        type: "string"
      },
      type: {
        type: "string",
        enum: %w[attribute input range-property select multiselect range date quantity_price]
      },
      # maybe value type support should be validated per attribute type
      value_type: {
        type: "string"
      },
      value: {
      },
      config: {
      }
    }
  }.freeze

  TYPE = "attribute"
end
