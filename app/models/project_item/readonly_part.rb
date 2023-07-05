# frozen_string_literal: true

class ProjectItem::ReadonlyPart
  attr_reader :attributes, :service, :offer, :bundle

  def initialize(parameters: {})
    @service = parameters["service"]
    @offer = parameters["offer"]
    @bundle = parameters["bundle"]

    @attributes = attributes_from_params(parameters["attributes"])
  end

  private

  def attributes_from_params(parameters)
    parameters.map { |p| Attribute.from_json(p) }
  end
end
