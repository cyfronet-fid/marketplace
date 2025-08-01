# frozen_string_literal: true

class Api::V1::ProviderSerializer < ActiveModel::Serializer
  attributes :id, :pid, :name
end
