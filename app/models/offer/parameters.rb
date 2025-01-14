# frozen_string_literal: true

module Offer::Parameters
  extend ActiveSupport::Concern

  included do
    validates_associated :parameters, unless: :draft?
    serialize :parameters, coder: Parameter::Array
  end

  def attributes
    (parameters || []).map { |param| Attribute.from_json(param.dump, validate: !draft?) }
  end

  def parameters_attributes=(attrs)
    if attrs.present?
      self.parameters =
        attrs.values.each_with_index.filter_map do |params, i|
          Parameter.for_type(params)&.new(params.merge(id: i.to_s))
        end
    else
      self.parameters = []
    end
  end
end
