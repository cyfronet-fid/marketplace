# frozen_string_literal: true

class Recommender::ProviderSerializer < ActiveModel::Serializer
  attributes :id, :pid, :name
end
