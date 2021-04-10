# frozen_string_literal: true

class OrderingApi::V1::OmsSerializer < ActiveModel::Serializer
  attributes :id, :name, :type, :default
  attribute :trigger_url, if: -> { object.trigger_url.present? }
  attribute :custom_params, if: -> { object.custom_params.present? }
end
