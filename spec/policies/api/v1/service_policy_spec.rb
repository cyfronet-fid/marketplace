# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::ServicePolicy do
  subject { described_class }

  let(:data_admin_user) { create(:user) }
  let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }
  let!(:service) { create(:service,
                          resource_organisation: create(:provider, data_administrators: [data_administrator])) }

  # TODO: scope test, even though it is tested in spec/requests/api/v1/services_controller_spec.rb

  permissions :show? do
    it "grants access for data administrator and managed service" do
      expect(subject).to permit(data_admin_user, service)
    end

    it "denies for data administrator and not managed service" do
      diff_data_admin_user = create(:user)
      diff_data_administrator = create(:data_administrator, email: diff_data_admin_user.email)

      expect(subject).to_not permit(diff_data_administrator, service)
    end

    it "denies for normal user" do
      expect(subject).to_not permit(create(:user), service)
    end
  end
end
