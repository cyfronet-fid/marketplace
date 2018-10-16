# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderPolicy do
  let(:user) { create(:user) }

  subject { described_class }

  permissions :index?, :create?, :new? do
    it "grants access for logged in user" do
      expect(subject).to permit(user)
    end
  end

  permissions :show? do
    it "grants access for order owner" do
      expect(subject).to permit(user, build(:order, user: user))
    end

    it "denies to see other user owners" do
      expect(subject).to_not permit(user, build(:order))
    end
  end

  it "returns only user orders" do
    service = create(:service)
    owned_order = create(:order, service: service, user: user)
    _other_user_order = create(:order, service: service)

    scope = described_class::Scope.new(user, Order.all)

    expect(scope.resolve).to contain_exactly(owned_order)
  end
end
