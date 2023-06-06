# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::ServicePolicy, type: :policy, backend: true do
  subject { described_class }

  let!(:data_admin_user) { create(:user) }
  let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }
  let!(:other_data_admin_user) { create(:user) }
  let(:other_data_admin) { create(:data_administrator, email: other_data_admin_user.email) }
  let!(:service) do
    create(:service, resource_organisation: create(:provider, data_administrators: [data_administrator]))
  end
  let!(:deleted_service) do
    create(
      :service,
      status: :deleted,
      resource_organisation: create(:provider, data_administrators: [data_administrator])
    )
  end

  permissions ".scope" do
    it "shows owned and not deleted services" do
      expect(subject::Scope.new(data_admin_user, Service).resolve).to contain_exactly(service)
      expect(subject::Scope.new(other_data_admin_user, Service).resolve).to eq([])
      expect(subject::Scope.new(create(:user), Service).resolve).to eq([])
    end
  end

  permissions :show? do
    it "grants access for data administrator and managed service" do
      expect(subject).to permit(data_admin_user, service)
    end

    it "denies for data administrator and not managed service" do
      expect(subject).to_not permit(other_data_admin_user, service)
    end

    it "denies for normal user" do
      expect(subject).to_not permit(create(:user), service)
    end

    it "denies for deleted service" do
      expect(subject).to_not permit(data_admin_user, deleted_service)
    end
  end
end
