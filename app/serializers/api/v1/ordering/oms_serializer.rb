# frozen_string_literal: true

class Api::V1::Ordering::OMSSerializer < ActiveModel::Serializer
  attributes :id, :name, :type, :default
  attribute :trigger, if: -> { object.trigger.present? }
  attribute :custom_params, if: -> { object.custom_params.present? }

  def trigger
    {
      url: object.trigger.url,
      method: object.trigger.method
    }
  end
end
