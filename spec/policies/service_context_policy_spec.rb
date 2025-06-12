# frozen_string_literal: true

require "rails_helper"

RSpec.describe ServiceContextPolicy, backend: true do
  let(:user) { create(:user) }
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

  permissions :show? do
    it "is granted for published service" do
      expect(subject).to permit(user, ServiceContext.new(build(:service, status: :published), false))
    end

    it "portfolio manager is granted for draft service" do
      allow(user).to receive(:coordinator?).and_return(true)
      expect(subject).to permit(user, ServiceContext.new(build(:service, status: :draft), true))
    end

    it "owner is granted for draft service" do
      service = build(:service, status: :draft)
      allow(service).to receive(:owned_by?).with(user).and_return(true)
      expect(subject).to permit(user, ServiceContext.new(service, true))
    end

    it "admin is granted for draft service" do
      service = build(:service, status: :draft)
      allow(service).to receive(:owned_by?).with(user).and_return(true)
      expect(subject).to permit(user, ServiceContext.new(service, true))
    end

    it "denies for draft service" do
      permit(user, build(:service, status: :draft))
    rescue e
      expect(e).to be_an_instance_of(Pundit::NotAuthorizedError)
      expect(e.query).to be("draft")
    end

    it "denies for deleted service" do
      allow(user).to receive(:coordinator?).and_return(true)

      service = build(:service, status: :draft)
      allow(service).to receive(:owned_by?).with(user).and_return(true)
      allow(service).to receive(:owned_by?).with(user).and_return(true)

      permit(user, build(:service, status: :deleted))
    rescue e
      expect(e).to be_an_instance_of(Pundit::NotAuthorizedError)
      expect(e.query).to be("removed")
    end
  end

  permissions :order? do
    it "grants access when there are offers" do
      service = create(:service)
      create(:offer, service: service)

      expect(subject).to permit(user, ServiceContext.new(service.reload, true))
    end

    it "denies when there is not offers" do
      expect(subject).to_not permit(user, ServiceContext.new(build(:service), true))
    end
  end
end
