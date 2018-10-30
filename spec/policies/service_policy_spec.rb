# frozen_string_literal: true

require "rails_helper"

RSpec.describe ServicePolicy do
  let(:user) { create(:user) }

  subject { described_class }

  permissions :order? do
    it "grants access when there are offers" do
      service = create(:service)
      create(:offer, service: service)

      expect(subject).to permit(user, service)
    end

    it "denies when there is not offers" do
      expect(subject).to_not permit(user, build(:service))
    end
  end
end
