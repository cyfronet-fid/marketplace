# frozen_string_literal: true

require "rails_helper"

RSpec.describe Filter::TargetUser, backend: true do
  context "#options" do
    let!(:target_user1) { create(:target_user) }
    let!(:target_user2) { create(:target_user) }
    let!(:service1) { create(:service, target_users: [target_user1]) }
    let!(:service2) { create(:service, target_users: [target_user1, target_user2]) }
    let!(:category) { create(:category, services: [service1]) }
    let!(:counters) { { target_user1.id => 2, target_user2.id => 1 } }

    it "returns all target_users with services count if no category is specified" do
      filter = described_class.new
      filter.counters = counters

      expect(filter.options).to contain_exactly(
        { name: target_user1.name, id: target_user1.id, count: 2 },
        { name: target_user2.name, id: target_user2.id, count: 1 }
      )
    end
  end
end
