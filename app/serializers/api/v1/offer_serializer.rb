# frozen_string_literal: true

class Api::V1::OfferSerializer < ActiveModel::Serializer
  attribute :iid, key: :id
  attributes :name, :description, :parameters, :order_type, :order_url
  attribute  :internal, if: -> { object.order_required? }
  attribute :primary_oms_id, if: -> { object.internal? }
  # TODO: https://github.com/cyfronet-fid/marketplace/issues/1964
  attribute :oms_params, if: -> { object.internal? && object.oms_params.present? }

  def primary_oms_id
    object.current_oms.id
  end
end
