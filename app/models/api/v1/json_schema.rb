# frozen_string_literal: true

# A schema of the OpenAPI 3.0 dialect in the form of a JSON Schema.
# OpenAPI 3.0 uses the `nullable` keyword for a value that can be null.
# JSON Schema does not have the `nullable` keyword.
# A nullable schema thus becomes a `oneOf` of the schema and the null type.
class Api::V1::JsonSchema
  NULL_TYPE = { "type" => "null" }.freeze

  def initialize(schema)
    @schema = schema
  end

  def to_h
    convert(@schema)
  end

  private

  def convert(node)
    case node
    when Array
      node.map { |item| convert(item) }
    when Hash
      convert_hash(node)
    else
      node
    end
  end

  def convert_hash(node)
    return node.transform_values { |value| convert(value) } unless node["nullable"] == true

    { "oneOf" => [convert(node.except("nullable")), NULL_TYPE] }
  end
end
