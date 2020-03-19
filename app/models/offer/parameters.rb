# frozen_string_literal: true

module Offer::Parameters
  extend ActiveSupport::Concern

  included do
    validates_associated :parameters
  end

  def attributes
    (parameters || []).map { |param| Attribute.from_json(param) }
  end

  def parameters
    @parameters || []
  end

  def parameters_attributes=(attrs)
    @parameters = attrs.map { |i, params| AttributeTemplate.build(params) }.reject(&:blank?)
  end
end
