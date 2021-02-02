# frozen_string_literal: true

class ServiceSerializer < ActiveModel::Serializer
  attribute :slug, key: :id
  attribute :pid, key: :eid
  attributes :name, :description, :status
end
