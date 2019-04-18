# frozen_string_literal: true

require "rails_helper"

RSpec.describe Filter::Rating do
  context "call" do
    it "filters services basing on ranking" do
      high_ranking = create(:service, rating: 3)
      create(:service, rating: 1)
      filter = described_class.new(params: { "rating" => "2" })

      expect(filter.call(Service.all)).to contain_exactly(high_ranking)
    end
  end
end
