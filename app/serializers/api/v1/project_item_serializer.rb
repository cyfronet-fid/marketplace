# frozen_string_literal: true

class Api::V1::ProjectItemSerializer < ActiveModel::Serializer
  attribute :id
  attribute :project_id
  attribute :status
  attribute :attribute_extractor, key: :attributes
  attribute :oms_params, if: -> { object.offer&.oms_params.present? }
  attribute :user_secrets

  def id
    object.iid
  end

  def status
    { value: object.status, type: object.status_type }
  end

  def attribute_extractor
    hash = {
      category: object.service.present? ? object.service.categories&.first&.name : nil,
      service: object.service&.name,
      offer: object.name,
      offer_properties: object.properties || [],
      platforms: object.service&.platforms&.pluck(:name) || [],
      request_voucher: object.request_voucher,
      order_type: object.order_type
    }
    hash[:supplied_voucher_id] = object.voucher_id if object.voucher_id.present?
    hash
  end

  def oms_params
    object.offer.oms_params
    # TODO: https://github.com/cyfronet-fid/marketplace/issues/1964
  end

  def user_secrets
    non_obfuscated = instance_options[:non_obfuscated_user_secrets] || []
    object.user_secrets.to_h { |k, v| non_obfuscated.include?(k) ? [k, v] : [k, "<OBFUSCATED>"] }
  end
end
