# frozen_string_literal: true

require "rails_helper"

RSpec.describe ServicePolicy do
  let(:user) { create(:user) }
  let(:scope) { Service.where(status: :published) }

  subject { described_class }

  def resolve
    subject::Scope.new(user, scope).resolve
  end

  permissions ".scope" do
    it "not allows draft services" do
      service = create(:service, status: :draft)

      expect(resolve.count).to eq(0)
    end

    it "allows published services" do
      service = create(:service, status: :published)

      expect(resolve.count).to eq(1)
    end
  end

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

  permissions :offers_show? do
    it "grants when there is more than on offer" do
      service = create(:service)
      create_list(:offer, 2, service: service)

      expect(subject).to permit(user, service)
    end

    it "denies when there is only one offer" do
      service = create(:service)
      create(:offer, service: service)

      expect(subject).to_not permit(user, service)
    end

    it "denies when there is not offers" do
      expect(subject).to_not permit(user, build(:service))
    end
  end
end
