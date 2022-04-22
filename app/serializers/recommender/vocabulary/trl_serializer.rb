# frozen_string_literal: true

class Recommender::Vocabulary::TrlSerializer < ActiveModel::Serializer
  attributes :id, :name, :description
end
