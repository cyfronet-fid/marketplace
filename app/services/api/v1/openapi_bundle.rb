# frozen_string_literal: true

# Joins the OpenAPI documents of a directory into one document.
# The class moves each schema that a document gets from a file to the components of the one document.
class Api::V1::OpenapiBundle < ApplicationService
  INFO = {
    "title" => "EOSC Marketplace API",
    "version" => "v1",
    "description" => "All the REST APIs of the EOSC Marketplace in one document"
  }.freeze
  COMPONENTS_PREFIX = "#/components/"
  SCHEMAS_PREFIX = "#{COMPONENTS_PREFIX}schemas/".freeze

  def initialize(root)
    super()
    @root = Pathname(root)
    @schemas = {}
  end

  def call
    documents.reduce(:deep_merge).deep_merge("info" => INFO, "components" => { "schemas" => @schemas })
  end

  private

  def documents
    @root.glob("*_swagger.json").sort.map { |file| link(JSON.parse(file.read), file) }
  end

  def link(node, file)
    case node
    when Array
      node.map { |item| link(item, file) }
    when Hash
      if file_reference?(node)
        { "$ref" => "#{SCHEMAS_PREFIX}#{component(node["$ref"], file)}" }
      else
        node.transform_values { |value| link(value, file) }
      end
    else
      node
    end
  end

  def file_reference?(node)
    node["$ref"].is_a?(String) && !node["$ref"].start_with?(COMPONENTS_PREFIX)
  end

  # A reference has the path of a file, a key in the file, or the two parts with "#" between them.
  # The name of the component comes from the path and the key, thus the name is unique.
  def component(reference, file)
    path, key = reference.split("#", 2)
    target = path.empty? ? file : file.dirname.join(path)
    keys = key.to_s.delete_prefix("/").split("/")
    name = [target.relative_path_from(@root).sub_ext(""), *keys].join("_").tr("/", "_")
    add_schema(name, target, keys) unless @schemas.key?(name)
    name
  end

  # The empty entry stops a loop when two schemas refer to each other.
  def add_schema(name, file, keys)
    @schemas[name] = {}
    @schemas[name] = link(keys.reduce(JSON.parse(file.read)) { |part, key| part.fetch(key) }, file)
  end
end
