# frozen_string_literal: true

class Api::V1::Offering::OMSSerializer < ActiveModel::Serializer
  attributes :id, :name, :type
  attribute :custom_params, if: -> { object.custom_params.present? }

  def custom_params
    object.custom_params.transform_values { |param| { mandatory: param["mandatory"] } }
  end
end
