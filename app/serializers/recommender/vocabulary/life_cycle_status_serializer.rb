# frozen_string_literal: true

class Recommender::Vocabulary::LifeCycleStatusSerializer < ActiveModel::Serializer
  attributes :id, :name, :description
end
