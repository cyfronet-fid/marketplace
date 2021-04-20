# frozen_string_literal: true

class ServiceSerializer < ActiveModel::Serializer
  attribute :slug, key: :id
  attribute :pid, key: :eid
  attributes :name, :description, :status
  attribute :available_oms

  def available_oms
    object.available_oms.map { |oms| OrderingApi::V1::OmsSerializer.new(oms).as_json }
  end
end
