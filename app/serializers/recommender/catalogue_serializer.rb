# frozen_string_literal: true

class Recommender::CatalogueSerializer < ActiveModel::Serializer
  attributes :id, :pid, :name
end
