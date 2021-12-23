# frozen_string_literal: true

class ProjectItem::Part
  attr_reader :offer, :attributes

  def initialize(offer:, parameters: nil)
    @offer = offer

    parameters = parameters || offer.parameters.dup || []
    @attributes = attributes_from_params(parameters)
  end

  def update(values)
    values.each { |id, value| update_attribute(id, value) }
  end

  def validate
    attributes.map(&:validate).all?
  end

  def to_hash
    { "offer_id" => offer.id, "attributes" => attributes.map(&:to_json) }
  end

  def to_json(*_args)
    attributes.map(&:to_json)
  end

  def id
    offer.id.to_s
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
