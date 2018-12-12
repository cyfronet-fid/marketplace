# frozen_string_literal: true

require "rails_helper"

RSpec.describe Backoffice::OfferPolicy do
  let(:user) { create(:user, roles: [:service_owner]) }
  let(:service) { create(:service, owners: [user]) }

  subject { described_class }

  permissions :new?, :create?, :update?, :destroy? do
    it "grants access" do
      expect(subject).to permit(user, build(:offer, service: service))
    end
  end
end
