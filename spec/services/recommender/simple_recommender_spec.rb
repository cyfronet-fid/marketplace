# frozen_string_literal: true

require "rails_helper"

RSpec.describe Recommender::SimpleRecommender, backend: true do
  include SimpleRecommenderSpecHelper
  before :context do
    @categories, @services = populate_database
  end

  [1, 2, 3].each do |n|
    context "Simple recommender_lib service call with n=#{n} returns" do
      before :context do
        @recommended_services = Recommender::SimpleRecommender.new.call n
      end

      it "an array" do
        expect(@recommended_services).to be_an(Array)
      end

      it "#{n} objects" do
        expect(@recommended_services.count).to eq(n)
      end

      it "unique objects" do
        expect(@recommended_services.count).to eq(@recommended_services.uniq.count)
      end

      it "services" do
        expect(@recommended_services).to all(be_an(Service))
      end

      it "services of most popular category" do
        expect(@recommended_services.map { |service| service.categories.first }).to all(eq(@categories[0]))
      end

      it "services in the order of the most popular" do
        recommended_services_ids = @recommended_services[0..n - 1].map(&:id)
        most_popular_services_ids = @services[0..n - 1].map(&:id)
        expect(recommended_services_ids).to match_array(most_popular_services_ids)
      end
    end
  end
end
