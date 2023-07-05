# frozen_string_literal: true

class ProjectItem::Attributes
  attr_reader :offer, :bundle, :attributes

  def initialize(offer:, parameters: nil)
    @offer = offer
    parameters = @offer.parameters.map(&:dump) if parameters.blank?
    @attributes = attributes_from_params(parameters)
  end

  def update(values)
    values.each { |id, value| update_attribute(id, value) }
  end

  def to_json(*_args)
    attributes.map(&:to_json)
  end

  private

  def attributes_from_params(parameters)
    parameters.map { |p| Attribute.from_json(p) }
  end

  def update_attribute(id, value)
    attributes_hsh[id]&.value_from_param(value)
  end

  def attributes_hsh
    @attributes_hsh ||= attributes.index_by(&:id)
  end
end
