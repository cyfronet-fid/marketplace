# frozen_string_literal: true

class Recommender::Vocabulary::AccessModeSerializer < ActiveModel::Serializer
  attributes :id, :name, :description
end
