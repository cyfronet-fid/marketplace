# frozen_string_literal: true

class Api::V1::Ordering::OMSSerializer < ActiveModel::Serializer
  attributes :id, :name, :type, :default
  attribute :trigger, if: -> { object.trigger.present? }
  attribute :custom_params, if: -> { object.custom_params.present? }

  def trigger
    {
      url: object.trigger.url,
      method: object.trigger.method,
      authorization: trigger_authorization
    }.select { |_, value| value.present? }
  end

  private

  def trigger_authorization
    auth = object.trigger&.authorization
    return nil if auth.blank?
    { user: auth.user, password: auth.password } if auth.is_a?(OMS::Authorization::Basic)
  end
end
