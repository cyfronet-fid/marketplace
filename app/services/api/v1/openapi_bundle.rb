# frozen_string_literal: true

# Joins the OpenAPI documents of a directory into one document.
# The class replaces each reference to a file with the content of the file.
class Api::V1::OpenapiBundle < ApplicationService
  INFO = {
    "title" => "EOSC Marketplace API",
    "version" => "v1",
    "description" => "All the REST APIs of the EOSC Marketplace in one document"
  }.freeze
  COMPONENTS_PREFIX = "#/components/"

  def initialize(root)
    super()
    @root = Pathname(root)
  end

  def call
    documents.reduce(:deep_merge).merge("info" => INFO)
  end

  private

  def documents
    @root.glob("*_swagger.json").sort.map { |file| inline(JSON.parse(file.read), file) }
  end

  def inline(node, file)
    case node
    when Array
      node.map { |item| inline(item, file) }
    when Hash
      if file_reference?(node)
        inline(*target(node["$ref"], file))
      else
        node.transform_values do |value|
          inline(value, file)
        end
      end
    else
      node
    end
  end

  def file_reference?(node)
    node["$ref"].is_a?(String) && !node["$ref"].start_with?(COMPONENTS_PREFIX)
  end

  # A reference has the path of a file, a key in the file, or the two parts with "#" between them.
  def target(reference, file)
    path, key = reference.split("#", 2)
    target_file = path.empty? ? file : file.dirname.join(path)
    schema = key.to_s.delete_prefix("/").split("/").reduce(JSON.parse(target_file.read)) do |part, name|
      part.fetch(name)
    end
    [schema, target_file]
  end
end
