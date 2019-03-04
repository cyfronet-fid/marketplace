# frozen_string_literal: true

class ProjectItem::Part
  attr_reader :offer, :attributes

  def initialize(offer:, parameters: nil)
    @offer = offer
    @attributes = attributes_from_params(parameters || offer.parameters.dup || [])
  end

  def update(values)
    values.each { |id, value| update_attribute(id, value) }
  end

  def validate
    attributes.map { |a| a.validate }.all?
  end

  def to_hash
    attributes.map { |a| a.to_json }
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
      @attributes_hsh ||= attributes.map { |p| [p.id, p] }.to_h
    end
end
