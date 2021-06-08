# frozen_string_literal: true

class Api::V1::ServiceSerializer < ActiveModel::Serializer
  attribute :slug, key: :id
  attribute :pid, key: :eid
  attributes :name, :description, :status
  attribute :available_omses

  def available_omses
    object.available_omses.map { |oms| Api::V1::Offering::OMSSerializer.new(oms).as_json }
  end
end
