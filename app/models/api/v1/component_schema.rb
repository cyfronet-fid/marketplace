# frozen_string_literal: true

# A component schema of the OpenAPI document.
# A file in swagger/v1/schemas is one component schema.
# The name of the file is the name of the component.
class Api::V1::ComponentSchema
  DIRECTORY = Rails.root.join("swagger/v1/schemas")

  def self.all
    @all ||= Dir[DIRECTORY.join("*.json")].to_h do |file|
      [File.basename(file, ".json"), JSON.parse(File.read(file))]
    end
  end

  def initialize(name)
    @name = name
  end

  def validate!(payload)
    JSON::Validator.validate!(to_h, payload)
  end

  private

  def to_h
    { "$ref" => "#/components/schemas/#{@name}", "components" => { "schemas" => self.class.all } }
  end
end
