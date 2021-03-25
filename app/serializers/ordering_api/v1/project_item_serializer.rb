# frozen_string_literal: true

class OrderingApi::V1::ProjectItemSerializer < ActiveModel::Serializer
  attributes :id, :project_id
  attribute :status
  attribute :attribute_extractor, key: :attributes
  attribute :oms_params, if: -> { object.offer.oms_params.present? }

  def status
    {
      value: object.status,
      type: object.status_type
    }
  end

  def attribute_extractor
    {
      category: object.service.categories&.first.name,
      service: object.service.name,
      offer: object.name,
      offer_properties: object.properties,
      platforms: object.service.platforms.pluck(:name),
      request_voucher: object.request_voucher,
      order_type: object.order_type,
    }
  end

  def oms_params
    object.offer.oms_params
  end
end
