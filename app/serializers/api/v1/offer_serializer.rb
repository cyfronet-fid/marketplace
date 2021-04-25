# frozen_string_literal: true

class Api::V1::OfferSerializer < ActiveModel::Serializer
  attribute :iid, key: :id
  attributes :name, :description, :parameters, :order_type, :webpage, :internal, :order_url
  attribute :primary_oms_id
  attribute :oms_params, if: -> { object.oms_params.present? } # TODO: https://github.com/cyfronet-fid/marketplace/issues/1964

  def primary_oms_id
    object.current_oms.id
  end
end
