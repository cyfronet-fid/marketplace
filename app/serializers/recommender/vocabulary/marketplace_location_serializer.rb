# frozen_string_literal: true

class Recommender::Vocabulary::MarketplaceLocationSerializer < ActiveModel::Serializer
  attributes :id, :name, :description
end
