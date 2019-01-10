# frozen_string_literal: true

require "rails_helper"

RSpec.describe Backoffice::ServicePolicy do
  let(:user) { create(:user, roles: [:service_portfolio_manager]) }

  subject { described_class }

  permissions :index?, :new?, :create? do
    it "grants access" do
      expect(subject).to permit(user, build(:service))
    end
  end


  permissions :update? do
    it "grants access for all services" do
      expect(subject).to permit(user, build(:service))
    end
  end

  permissions :destroy? do
    it "grants access for all services" do
      expect(subject).to permit(user, build(:service))
    end

    it "denies when service has project_items attached" do
      service = create(:service)
      create(:project_item, offer: create(:offer, service: service))

      expect(subject).to_not permit(user, service)
    end
  end
end
