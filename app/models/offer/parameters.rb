# frozen_string_literal: true

module Offer::Parameters
  extend ActiveSupport::Concern

  included do
    validates_associated :parameters
    serialize :parameters, Parameter::Array
  end

  def attributes
    (parameters || []).map { |param| Attribute.from_json(param.dump) }
  end

  def parameters_attributes=(attrs)
    self.parameters = attrs.values.each_with_index
      .map { |params, i| Parameter.for_type(params).new(params.merge(id: i.to_s)) }
      .compact
  end
end
