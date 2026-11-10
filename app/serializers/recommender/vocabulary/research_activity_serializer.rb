# frozen_string_literal: true

class Recommender::Vocabulary::ResearchActivitySerializer < ActiveModel::Serializer
  attributes :id, :name, :description
end
