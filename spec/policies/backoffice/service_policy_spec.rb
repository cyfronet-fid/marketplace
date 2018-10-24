# frozen_string_literal: true

require "rails_helper"

RSpec.describe Backoffice::ServicePolicy do
  let(:user) { create(:user, roles: [:service_owner]) }

  subject { described_class }

  permissions :index?, :new?, :create? do
    it "grants access" do
      expect(subject).to permit(user, build(:service))
    end
  end


  permissions :update? do
    it "grants access for service owner" do
      expect(subject).to permit(user, build(:service, owner: user))
    end

    it "denies access for other users" do
      expect(subject).to_not permit(user, build(:service))
    end
  end

  permissions :destroy? do
    it "grants access for service owner" do
      expect(subject).to permit(user, build(:service, owner: user))
    end

    it "denies access for other users" do
      expect(subject).to_not permit(user, build(:service))
    end

    it "denies when service has project_items attached" do
      service = create(:service, owner: user)
      create(:project_item, offer: create(:offer, service: service))

      expect(subject).to_not permit(user, build(:service))
    end
  end
end
