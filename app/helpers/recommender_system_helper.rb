# frozen_string_literal: true

module RecommenderSystemHelper
  def get_naive_recommendation
    version = ab_test(:recommendation_panel)
    if version == "v1"
      Recommender::SimpleRecommender.new.call 3
    elsif version == "v2"
      Recommender::SimpleRecommender.new.call 2
    end
  end
end
