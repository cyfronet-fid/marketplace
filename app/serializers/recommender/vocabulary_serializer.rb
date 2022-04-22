# frozen_string_literal: true

class Recommender::VocabularySerializer < ActiveModel::Serializer
  attributes :id, :name, :description
end
