# frozen_string_literal: true

class Recommender::Vocabulary::ResearchStepSerializer < ActiveModel::Serializer
  attributes :id, :name, :description
end
