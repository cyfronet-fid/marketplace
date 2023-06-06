# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::OMSPolicy, type: :policy, backend: true do
  subject { described_class }

  let(:user1) { create(:user) }
  let(:user2) { create(:user) }
  let(:user3) { create(:user) }

  let(:oms1) { create(:oms, administrators: [user1]) }
  let(:oms2) { create(:oms, administrators: [user2]) }
  let(:oms3) { create(:oms, administrators: [user1, user2]) }

  permissions ".scope" do
    it "shows only administrated oms" do
      expect(subject::Scope.new(user1, OMS).resolve).to contain_exactly(oms1, oms3)
      expect(subject::Scope.new(user2, OMS).resolve).to contain_exactly(oms2, oms3)
      expect(subject::Scope.new(user3, OMS).resolve).to eq([])
    end
  end

  permissions :show? do
    it "grants permission to an oms admin only" do
      expect(subject).to permit(user1, oms1)
      expect(subject).to_not permit(user1, oms2)

      expect(subject).to permit(user2, oms2)
      expect(subject).to_not permit(user1, oms2)

      expect(subject).to_not permit(user3, oms1)
      expect(subject).to_not permit(user3, oms2)
    end
  end
end
