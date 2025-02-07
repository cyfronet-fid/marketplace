# frozen_string_literal: true

require "rails_helper"

RSpec.describe ServicePolicy, backend: true do
  let(:user) { create(:user) }
  let(:stranger) { create(:user) }
  let(:data_administrator) { create(:data_administrator, email: user.email) }
  let(:provider) { create(:provider, data_administrators: [data_administrator]) }
  let(:service) { create(:service, resource_organisation: provider) }

  subject { described_class }

  def resolve
    subject::Scope.new(user, Service).resolve
  end

  permissions ".scope" do
    it "not allows draft services" do
      create(:service, status: :draft)

      expect(resolve.count).to eq(0)
    end

    it "not allows deleted services" do
      create(:service, status: :deleted)

      expect(resolve.count).to eq(0)
    end

    it "allows published services" do
      create(:service, status: :published)

      expect(resolve.count).to eq(1)
    end
  end

  permissions :offers_show? do
    it "grants when there is more than on offer" do
      service = create(:service)
      create_list(:offer, 2, service: service)
      expect(subject).to permit(user, service.reload)
    end

    it "grants when there is only one offer" do
      service = create(:service)
      create(:offer, service: service)

      expect(subject).to permit(user, service.reload)
    end

    it "denies when there is not offers" do
      expect(subject).to_not permit(user, build(:service))
    end
  end

  permissions :errors_show? do
    let(:spm_user) { create(:user, roles: [:coordinator]) }

    it "grants access to data administrator" do
      expect(subject).to permit(user, service)
    end

    it "grants access to service portfolio manager" do
      expect(subject).to permit(spm_user, service)
    end

    it "denies when not data administrator" do
      expect(subject).to_not permit(stranger, service)
    end

    it "denies when data administrator of another service" do
      other_service = create(:service)
      expect(subject).to_not permit(user, other_service)
    end
  end

  permissions :data_administrator? do
    it "grants access when data administrator" do
      expect(subject).to permit(user, service)
    end

    it "denies when not data administrator" do
      expect(subject).to_not permit(stranger, service)
    end

    it "denies when data administrator of another resource" do
      other_service = create(:service)
      expect(subject).to_not permit(user, other_service)
    end
  end
end
