# frozen_string_literal: true

class Recommender::TargetUserSerializer < ActiveModel::Serializer
  attributes :id, :name, :description
end
