# frozen_string_literal: true

class Recommender::Vocabulary::AccessTypeSerializer < ActiveModel::Serializer
  attributes :id, :name, :description
end
