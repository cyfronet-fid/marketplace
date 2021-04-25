# frozen_string_literal: true

class Api::V1::OMSSerializer < ActiveModel::Serializer
  attributes :id, :name, :type, :default
  attribute :trigger_url, if: -> { object.trigger_url.present? }
  attribute :custom_params, if: -> { object.custom_params.present? }
end
