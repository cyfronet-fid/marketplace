# frozen_string_literal: true

require "rails_helper"

RSpec.describe ServicePolicy do
  let(:user) { create(:user) }

  subject { described_class }

  def resolve
    subject::Scope.new(user, Service).resolve
  end

  permissions ".scope" do
    it "not allows draft services" do
      create(:service, status: :draft)

      expect(resolve.count).to eq(0)
    end

    it "allows published services" do
      create(:service, status: :published)

      expect(resolve.count).to eq(1)
    end

    it "allows unverified services" do
      create(:service, status: :unverified)

      expect(resolve.count).to eq(1)
    end
  end

  permissions :show? do
    it "is granted for published service" do
      expect(subject).to permit(user, build(:service, status: :published))
    end

    it "is granted for unvefiried service" do
      expect(subject).to permit(user, build(:service, status: :unverified))
    end

    it "denies for draft service" do
      expect(subject).to_not permit(user, build(:service, status: :draft))
    end
  end

  permissions :order? do
    it "grants access when there are offers" do
      service = create(:service)
      create(:offer, service: service)

      expect(subject).to permit(user, service.reload)
    end

    it "denies when there is not offers" do
      expect(subject).to_not permit(user, build(:service))
    end
  end

  permissions :offers_show? do
    it "grants when there is more than on offer" do
      service = create(:service)
      create_list(:offer, 2, service: service)
      expect(subject).to permit(user, service.reload)
    end

    it "denies when there is only one offer" do
      service = create(:service)
      create(:offer, service: service)

      expect(subject).to_not permit(user, service.reload)
    end

    it "denies when there is not offers" do
      expect(subject).to_not permit(user, build(:service))
    end
  end
end
