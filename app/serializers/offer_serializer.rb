# frozen_string_literal: true

class OfferSerializer < ActiveModel::Serializer
  attribute :iid, key: :id
  attributes :name, :description, :parameters, :order_type, :webpage, :internal, :order_url
end
