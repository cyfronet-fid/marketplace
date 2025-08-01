# frozen_string_literal: true

class Api::V1::CatalogueSerializer < ActiveModel::Serializer
  attributes :id, :pid, :name
end
